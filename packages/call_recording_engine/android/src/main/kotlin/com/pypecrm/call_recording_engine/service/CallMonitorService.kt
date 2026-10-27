package com.pypecrm.call_recording_engine.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import com.pypecrm.call_recording_engine.data.CallEventDbHelper
import com.pypecrm.call_recording_engine.data.CallSettingsCache
import com.pypecrm.call_recording_engine.data.CallStatePrefs
import com.pypecrm.call_recording_engine.data.EngineStats
import com.pypecrm.call_recording_engine.data.NativeAuthPrefs
import com.pypecrm.call_recording_engine.data.NativeRecordingCapabilityPrefs
import com.pypecrm.call_recording_engine.data.PendingCallEvent
import com.pypecrm.call_recording_engine.data.PendingRecordingStore
import com.pypecrm.call_recording_engine.net.BackendApi
import com.pypecrm.call_recording_engine.scanner.NativeRecordingScanner
import com.pypecrm.call_recording_engine.sync.CallSyncWorker
import com.pypecrm.call_recording_engine.util.CallLogLookup
import com.pypecrm.call_recording_engine.util.PhoneNumberUtils
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File

/**
 * The persistent foreground service backing Tiers 0 and 4. Runs
 * continuously once monitoring is enabled (not just per-call) — a
 * long-lived foreground notification is deliberately harder for aggressive
 * OEM battery managers (Xiaomi/Oppo/etc.) to kill than a service that
 * starts and stops for every call, mirroring the reference implementation's
 * approach. [CallStateReceiver] is what's always alive across reboots (via
 * its manifest registration); it hands off to this service on each call.
 *
 * Only action taken is at call-end: Tier 0 (OEM native-recorder file, best
 * quality, polled for a short window after the call) → Tier 4 (metadata
 * only, always). See Dad-mobile/CALL_RECORDING_PLAN.md.
 */
class CallMonitorService : Service() {

    // SupervisorJob (not a plain Job) + a CoroutineExceptionHandler: without
    // both, an uncaught exception anywhere in handleCallEnded() - which runs
    // on every single call - crashes the whole app process instead of just
    // failing that one step. Confirmed as a real path: NativeRecordingScanner's
    // Tier 0 fallback lookup had exactly this kind of unguarded throw (see
    // its doc comment), reported as "PypeCRM Helper keeps stopping" during
    // calls. This is the safety net for whatever the next unguarded throw
    // turns out to be.
    private val exceptionHandler = CoroutineExceptionHandler { _, throwable ->
        Log.e(TAG, "Uncaught exception in CallMonitorService coroutine - call handling continues, this step failed", throwable)
    }
    private val jobScope = CoroutineScope(Dispatchers.IO + SupervisorJob() + exceptionHandler)

    private lateinit var callStatePrefs: CallStatePrefs
    private lateinit var nativeRecordingCapabilityPrefs: NativeRecordingCapabilityPrefs
    private lateinit var engineStats: EngineStats
    private lateinit var dbHelper: CallEventDbHelper
    private lateinit var settingsCache: CallSettingsCache
    private lateinit var api: BackendApi

    override fun onCreate() {
        super.onCreate()
        callStatePrefs = CallStatePrefs(this)
        nativeRecordingCapabilityPrefs = NativeRecordingCapabilityPrefs(this)
        engineStats = EngineStats(this)
        dbHelper = CallEventDbHelper.getInstance(this)
        settingsCache = CallSettingsCache(this)
        api = BackendApi(NativeAuthPrefs(this))
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Called unconditionally, first, for every entry point (including a
        // cold restart) — Android requires startForeground() shortly after
        // any startForegroundService() call, regardless of which action
        // triggered it. Typed via ServiceCompat rather than plain
        // startForeground(id, notification) — confirmed the hard way on a
        // real device that the `phoneCall` type (used previously) requires
        // MANAGE_OWN_CALLS or the default-dialer role on Android 14+, which
        // this app deliberately has neither of (it only monitors calls, it
        // doesn't manage them) — that mismatch crashed this exact call
        // (SecurityException) on every single call-end, before any
        // call-end processing ever ran. `dataSync` needs no such role.
        ServiceCompat.startForeground(
            this, NOTIFICATION_ID, buildNotification(statusTextFor(intent?.action)), ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
        )

        when (intent?.action) {
            ACTION_CALL_ENDED -> jobScope.launch { handleCallEnded() }
            ACTION_STOP -> {
                stopForeground(true)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> { /* ACTION_ENSURE_RUNNING / ACTION_CALL_RINGING / a plain OS restart */ }
        }
        return START_STICKY
    }

    private suspend fun handleCallEnded() {
        val startedAt = callStatePrefs.callStartTimeMillis
        val expectedNumberSuffix = PhoneNumberUtils.last10Digits(callStatePrefs.expectedNumber)
        callStatePrefs.expectedNumber = null // consumed — don't leak into the next call
        // Only trust likelyOutgoing as a CallLogLookup hint when THIS call
        // cycle actually reached OFFHOOK (see CallStatePrefs.
        // reachedOffhookThisCall's doc comment) — otherwise (a call that
        // rang and was never answered) it could still hold a stale value
        // left over from an earlier call.
        val expectedType = if (callStatePrefs.reachedOffhookThisCall && callStatePrefs.likelyOutgoing) "OUTGOING" else null

        val details = CallLogLookup.awaitLatestCallDetails(
            this, startedAt, expectedNumberSuffix.ifEmpty { null }, expectedType
        )
        if (details == null) {
            Log.w(TAG, "Call ended but no CallLog entry appeared — nothing to sync.")
            updateNotification(statusTextFor(null))
            return
        }

        settingsCache.refreshIfStale(api)
        val isOutgoing = details.callType == "OUTGOING"
        val directionAllowed = settingsCache.isDirectionAllowed(isOutgoing)

        val event = PendingCallEvent(
            phoneNumber = details.phoneNumber,
            durationSeconds = details.durationSeconds,
            callType = details.callType,
            timestampMillis = details.timestampMillis,
            hardwareId = details.hardwareId,
            callSessionId = null,
        )

        // CallLog DATE is when the call STARTED; OEM recorders finalize their
        // file when it ENDS. Matching against the start time meant any call
        // longer than the scanner's window (30s for the no-number fallback,
        // 5min otherwise) never found its Tier 0 recording.
        val callEndMillis = details.timestampMillis + details.durationSeconds * 1000L

        var uploaded = false
        // A recording that exists but couldn't be uploaded right now
        // (offline, server error) — kept and queued for retry instead of
        // deleted, so the audio isn't lost to a bad connection at call-end.
        var unsentRecording: File? = null
        if (directionAllowed && details.phoneNumber.isNotBlank()) {
            // Tier 0 — best quality, least permission risk, the only
            // recording source this app has.
            val tier0File = pollTier0(details.phoneNumber, callEndMillis)
            if (tier0File != null) {
                uploaded = runCatching { api.uploadRecording(event, tier0File) }.getOrDefault(false)
                if (uploaded) {
                    tier0File.delete()
                    engineStats.recordTier0Success(System.currentTimeMillis())
                } else {
                    unsentRecording = tier0File
                }
            }
        }
        val keptPath = if (!uploaded && unsentRecording != null) {
            PendingRecordingStore.keep(this, unsentRecording, details.hardwareId)
        } else null
        unsentRecording?.let { if (it.exists()) it.delete() }

        if (!uploaded) {
            // Tier 4: queue for the next sync pass (with the recording, if
            // one is waiting to be retried) — never block call-end
            // processing on network state, and never call bulk-sync per-call.
            dbHelper.enqueue(event.copy(recordingPath = keptPath))
            CallSyncWorker.scheduleNow(applicationContext)
        }
        // Lets CallLogReconciler skip this call instead of re-queuing it and
        // re-uploading its audio a second time.
        dbHelper.markHandled(details.hardwareId)

        updateNotification(statusTextFor(null))
    }

    private suspend fun pollTier0(phoneNumber: String, callEndMillis: Long): File? {
        // Most devices never produce a Tier 0 file at all (their OEM dialer
        // doesn't auto-record) — polling the full 9 attempts (~18s) after
        // every single call on one of those devices is 18s of active
        // background work for zero benefit, right in the window a rep is
        // most likely to immediately try something else. Once this device
        // has shown zero matches over several calls in a row, cut future
        // polls down to a quick check instead — see
        // NativeRecordingCapabilityPrefs's doc comment for why this stays
        // reversible rather than a permanent one-way switch.
        // A device that has EVER produced a Tier 0 file (e.g. Samsung, whose
        // own recorder is known to finalize the file a few seconds later
        // than other OEMs) always gets the full window even mid-miss-streak
        // — a miss there is far more likely a slow write than the device
        // suddenly losing support, and the short window was making that
        // exact case self-reinforcing (miss → shorter window → more misses).
        // Only a device that has NEVER matched gets the short/fast-skip poll.
        val maxAttempts = if (nativeRecordingCapabilityPrefs.isLikelyUnsupported &&
            !nativeRecordingCapabilityPrefs.hasEverMatched
        ) {
            NativeRecordingCapabilityPrefs.SHORT_POLL_ATTEMPTS
        } else {
            TIER0_POLL_ATTEMPTS
        }

        repeat(maxAttempts) { attempt ->
            val match = NativeRecordingScanner.scanOnce(this, phoneNumber, callEndMillis)
            if (match != null) {
                nativeRecordingCapabilityPrefs.recordCallOutcome(matchFound = true)
                return match
            }
            if (attempt < maxAttempts - 1) delay(TIER0_POLL_INTERVAL_MS)
        }
        nativeRecordingCapabilityPrefs.recordCallOutcome(matchFound = false)
        return null
    }

    private fun statusTextFor(action: String?): String = when (action) {
        ACTION_CALL_RINGING -> "Call ringing…"
        ACTION_STOP -> "Stopping…"
        else -> "Waiting for calls…"
    }

    private fun updateNotification(text: String) {
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, buildNotification(text))
    }

    private fun buildNotification(text: String): Notification =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("PypeCRM Helper")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID, "Call monitoring", NotificationManager.IMPORTANCE_LOW
        ).apply { description = "Shows when PypeCRM Helper is watching for calls" }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    override fun onDestroy() {
        jobScope.coroutineContext[Job]?.cancel()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val TAG = "CallMonitorService"
        private const val CHANNEL_ID = "call_monitor_channel"
        private const val NOTIFICATION_ID = 4201

        // ~2s apart for ~16-18s total — several OEMs finalize the recording
        // file a few seconds after call end (the exact gap
        // NativeRecordingScanner's old single-query version used to miss).
        private const val TIER0_POLL_ATTEMPTS = 9
        private const val TIER0_POLL_INTERVAL_MS = 2000L

        const val ACTION_ENSURE_RUNNING = "com.pypecrm.call_recording_engine.action.ENSURE_RUNNING"
        const val ACTION_CALL_RINGING = "com.pypecrm.call_recording_engine.action.CALL_RINGING"
        const val ACTION_CALL_ENDED = "com.pypecrm.call_recording_engine.action.CALL_ENDED"
        const val ACTION_STOP = "com.pypecrm.call_recording_engine.action.STOP"
    }
}
