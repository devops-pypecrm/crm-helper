package com.pypecrm.call_recording_engine.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.pypecrm.call_recording_engine.data.CallEventDbHelper
import com.pypecrm.call_recording_engine.data.CallSettingsCache
import com.pypecrm.call_recording_engine.data.CallStatePrefs
import com.pypecrm.call_recording_engine.data.EngineStats
import com.pypecrm.call_recording_engine.data.MediaProjectionTokenStore
import com.pypecrm.call_recording_engine.data.NativeAuthPrefs
import com.pypecrm.call_recording_engine.data.PendingCallEvent
import com.pypecrm.call_recording_engine.net.BackendApi
import com.pypecrm.call_recording_engine.recorder.CallAudioRecorder
import com.pypecrm.call_recording_engine.scanner.NativeRecordingScanner
import com.pypecrm.call_recording_engine.sync.CallSyncWorker
import com.pypecrm.call_recording_engine.util.CallLogLookup
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File

/**
 * The persistent foreground service backing Tiers 0, 1, 2, and 4 (Tier 3
 * lives in its own [ProjectionCaptureService] — see that class's doc
 * comment for why). Runs continuously once monitoring is enabled (not just
 * per-call) — a long-lived foreground notification is deliberately harder
 * for aggressive OEM battery managers (Xiaomi/Oppo/etc., see the plan's
 * Risks section) to kill than a service that starts and stops for every
 * call, mirroring the reference implementation's approach.
 * [CallStateReceiver] is what's always alive across reboots (via its
 * manifest registration); it hands off to this service on each call.
 *
 * Fallback order at call-end is Tier 0 (OEM native-recorder file, best
 * quality) → Tier 1/2 (our own MediaRecorder capture, started live at
 * [ACTION_CALL_ACTIVE] since it can't be done retroactively) → Tier 3 (only
 * if 1/2 couldn't even start) → Tier 4 (metadata only). See
 * Dad-mobile/CALL_RECORDING_PLAN.md.
 */
class CallMonitorService : Service() {

    private val jobScope = CoroutineScope(Dispatchers.IO + Job())

    private lateinit var callStatePrefs: CallStatePrefs
    private lateinit var engineStats: EngineStats
    private lateinit var dbHelper: CallEventDbHelper
    private lateinit var settingsCache: CallSettingsCache
    private lateinit var api: BackendApi
    private lateinit var audioRecorder: CallAudioRecorder

    /** True when [startLiveCaptureIfAllowed] handed this call off to
     * [ProjectionCaptureService] (Tier 3) because Tiers 1/2 couldn't even
     * start — that service owns finishing the call end-to-end (CallLog
     * lookup, upload-or-queue) in that case, so [handleCallEnded] must not
     * also process it (would double-queue/double-upload). */
    @Volatile private var tier3Delegated = false

    override fun onCreate() {
        super.onCreate()
        callStatePrefs = CallStatePrefs(this)
        engineStats = EngineStats(this)
        dbHelper = CallEventDbHelper.getInstance(this)
        settingsCache = CallSettingsCache(this)
        api = BackendApi(NativeAuthPrefs(this))
        audioRecorder = CallAudioRecorder(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Called unconditionally, first, for every entry point (including a
        // cold restart) — Android requires startForeground() shortly after
        // any startForegroundService() call, regardless of which action
        // triggered it.
        startForeground(NOTIFICATION_ID, buildNotification(statusTextFor(intent?.action)))

        when (intent?.action) {
            ACTION_CALL_ACTIVE -> jobScope.launch { startLiveCaptureIfAllowed() }
            ACTION_CALL_ENDED -> jobScope.launch { handleCallEnded() }
            ACTION_STOP -> {
                if (audioRecorder.isRecording) audioRecorder.stop()?.delete()
                stopForeground(true)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> { /* ACTION_ENSURE_RUNNING / ACTION_CALL_RINGING / a plain OS restart */ }
        }
        return START_STICKY
    }

    /** Live capture must start now — unlike Tier 0/4 it can't be
     * reconstructed after the fact. Gated on [CallSettingsCache] using the
     * best-effort live direction guess ([CallStatePrefs.likelyOutgoing]),
     * since the CallLog's authoritative direction isn't available until
     * the call ends — recording (not just uploading) is skipped outright
     * when the org has this direction's auto-record setting off, per the
     * plan's consent-law non-negotiable. */
    private suspend fun startLiveCaptureIfAllowed() {
        settingsCache.refreshIfStale(api)
        if (!settingsCache.isDirectionAllowed(callStatePrefs.likelyOutgoing)) {
            Log.d(TAG, "Live recording skipped — org has recording off for this direction.")
            return
        }
        if (audioRecorder.start()) return // Tier 1 (VOICE_COMMUNICATION/MIC) or Tier 2 (VOICE_RECOGNITION)

        Log.w(TAG, "Tiers 1/2 failed to start at all — trying Tier 3 if a MediaProjection token exists.")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && MediaProjectionTokenStore.hasToken()) {
            tier3Delegated = true
            startService(
                Intent(this, ProjectionCaptureService::class.java).apply {
                    action = ProjectionCaptureService.ACTION_START
                }
            )
        }
    }

    private suspend fun handleCallEnded() {
        if (tier3Delegated) {
            tier3Delegated = false
            startService(
                Intent(this, ProjectionCaptureService::class.java).apply {
                    action = ProjectionCaptureService.ACTION_STOP
                }
            )
            updateNotification(statusTextFor(null))
            return
        }

        val startedAt = callStatePrefs.callStartTimeMillis
        // Read the tier BEFORE stop() — it resets to null.
        val capturedTier = audioRecorder.activeTier
        val liveFile = if (audioRecorder.isRecording) audioRecorder.stop() else null

        val details = CallLogLookup.awaitLatestCallDetails(this, startedAt)
        if (details == null) {
            Log.w(TAG, "Call ended but no CallLog entry appeared — nothing to sync.")
            liveFile?.delete()
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

        var uploaded = false
        if (directionAllowed && details.phoneNumber.isNotBlank()) {
            // Tier 0 first — best quality, least permission risk.
            val tier0File = pollTier0(details.phoneNumber, details.timestampMillis)
            if (tier0File != null) {
                uploaded = runCatching { api.uploadRecording(event, tier0File) }.getOrDefault(false)
                tier0File.delete()
                if (uploaded) engineStats.recordTier0Success(System.currentTimeMillis())
            }

            // Tier 1/2 fallback — only if Tier 0 didn't produce a usable
            // upload, and only if the file actually looks like real audio
            // (see CallAudioRecorder.isLikelySilent — the "succeeded but
            // silent" guard the plan calls out for these tiers).
            if (!uploaded && liveFile != null &&
                !CallAudioRecorder.isLikelySilent(liveFile, details.durationSeconds)
            ) {
                uploaded = runCatching { api.uploadRecording(event, liveFile) }.getOrDefault(false)
                if (uploaded) {
                    val now = System.currentTimeMillis()
                    if (capturedTier == 2) engineStats.recordTier2Success(now) else engineStats.recordTier1Success(now)
                }
            }
        }
        liveFile?.let { if (it.exists()) it.delete() }

        if (!uploaded) {
            // Tier 4: queue metadata-only for the next batched bulk-sync —
            // never block call-end processing on network state, and never
            // call bulk-sync per-call (server rate-limits it to 1/user/10min).
            dbHelper.enqueue(event)
            CallSyncWorker.scheduleNow(applicationContext)
        }

        updateNotification(statusTextFor(null))
    }

    private suspend fun pollTier0(phoneNumber: String, callEndMillis: Long): File? {
        repeat(TIER0_POLL_ATTEMPTS) { attempt ->
            val match = NativeRecordingScanner.scanOnce(this, phoneNumber, callEndMillis)
            if (match != null) return match
            if (attempt < TIER0_POLL_ATTEMPTS - 1) delay(TIER0_POLL_INTERVAL_MS)
        }
        return null
    }

    private fun statusTextFor(action: String?): String = when (action) {
        ACTION_CALL_RINGING -> "Call ringing…"
        ACTION_CALL_ACTIVE -> "Call in progress…"
        ACTION_STOP -> "Stopping…"
        else -> "Waiting for calls…"
    }

    private fun updateNotification(text: String) {
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, buildNotification(text))
    }

    private fun buildNotification(text: String): Notification =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Pype Call Recorder")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID, "Call monitoring", NotificationManager.IMPORTANCE_LOW
        ).apply { description = "Shows when Pype Call Recorder is watching for calls" }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    override fun onDestroy() {
        if (audioRecorder.isRecording) audioRecorder.stop()?.delete()
        jobScope.coroutineContext[Job]?.cancel()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val TAG = "CallMonitorService"
        private const val CHANNEL_ID = "call_monitor_channel"
        private const val NOTIFICATION_ID = 4201

        // ~2s apart for ~16-18s total — the plan calls for a ~15-20s window
        // since several OEMs finalize the recording file a few seconds
        // after call end (the exact gap NativeRecordingScanner's old
        // single-query version used to miss).
        private const val TIER0_POLL_ATTEMPTS = 9
        private const val TIER0_POLL_INTERVAL_MS = 2000L

        const val ACTION_ENSURE_RUNNING = "com.pypecrm.call_recording_engine.action.ENSURE_RUNNING"
        const val ACTION_CALL_RINGING = "com.pypecrm.call_recording_engine.action.CALL_RINGING"
        const val ACTION_CALL_ACTIVE = "com.pypecrm.call_recording_engine.action.CALL_ACTIVE"
        const val ACTION_CALL_ENDED = "com.pypecrm.call_recording_engine.action.CALL_ENDED"
        const val ACTION_STOP = "com.pypecrm.call_recording_engine.action.STOP"
    }
}
