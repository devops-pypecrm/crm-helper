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
import com.pypecrm.call_recording_engine.data.PendingCallEvent
import com.pypecrm.call_recording_engine.net.BackendApi
import com.pypecrm.call_recording_engine.recorder.ProjectionAudioRecorder
import com.pypecrm.call_recording_engine.sync.CallSyncWorker
import com.pypecrm.call_recording_engine.util.CallLogLookup
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

/**
 * Tier 3's own dedicated foreground service, deliberately isolated from
 * [CallMonitorService].
 *
 * Why a separate service: Android checks EVERY manifest-declared
 * foregroundServiceType on a service whenever it's started via the
 * type-inferring `startForeground(id, notification)` overload — the one
 * CallMonitorService uses for its routine per-call notification updates.
 * Folding `mediaProjection` into CallMonitorService's own type list would
 * make its normal phoneCall/microphone starts (i.e. every call, whether or
 * not a Tier 3 token even exists) also have to satisfy the mediaProjection
 * precondition, which Android 14+ enforces requires an active, currently
 * consented projection session — failing that on every ordinary call would
 * crash monitoring entirely just for declaring Tier 3 support at all. This
 * is a real risk the old blueprint's single combined
 * `foregroundServiceType="phoneCall|microphone|mediaProjection"` carries,
 * and plausibly one contributor to the reliability problems that prompted
 * this rebuild — isolating it here avoids the whole class of failure.
 *
 * Because [CallMonitorService] only ever hands a call off to this service
 * when Tiers 1/2 couldn't start at all (see its `tier3Delegated` flag),
 * this service owns finishing that call completely — CallLog lookup,
 * silence check, upload-or-queue — the same job
 * `CallMonitorService.handleCallEnded` does for the other tiers, just for
 * this one call, so the two services never both try to process it.
 */
class ProjectionCaptureService : Service() {
    private val jobScope = CoroutineScope(Dispatchers.IO + Job())
    private val recorder by lazy { ProjectionAudioRecorder(this) }

    private lateinit var callStatePrefs: CallStatePrefs
    private lateinit var engineStats: EngineStats
    private lateinit var dbHelper: CallEventDbHelper
    private lateinit var settingsCache: CallSettingsCache
    private lateinit var api: BackendApi

    override fun onCreate() {
        super.onCreate()
        callStatePrefs = CallStatePrefs(this)
        engineStats = EngineStats(this)
        dbHelper = CallEventDbHelper.getInstance(this)
        settingsCache = CallSettingsCache(this)
        api = BackendApi(NativeAuthPrefs(this))
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceCompat.startForeground(
                this, NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            // Unreachable in practice (ProjectionAudioRecorder itself is
            // @RequiresApi(Q)) but kept so this call never throws pre-Q.
            startForeground(NOTIFICATION_ID, notification)
        }

        when (intent?.action) {
            ACTION_STOP -> jobScope.launch { finishAndStop() }
            else -> {
                if (recorder.start() == null) {
                    Log.w(TAG, "Tier 3 capture failed to start — stopping immediately.")
                    stopSelfSafely()
                }
            }
        }
        return START_NOT_STICKY
    }

    private suspend fun finishAndStop() {
        val startedAt = callStatePrefs.callStartTimeMillis
        val file = recorder.stop()

        val details = CallLogLookup.awaitLatestCallDetails(this, startedAt)
        if (details == null) {
            Log.w(TAG, "Tier 3: call ended but no CallLog entry appeared — nothing to sync.")
            file?.delete()
            stopSelfSafely()
            return
        }

        settingsCache.refreshIfStale(api)
        val directionAllowed = settingsCache.isDirectionAllowed(details.callType == "OUTGOING")

        val event = PendingCallEvent(
            phoneNumber = details.phoneNumber,
            durationSeconds = details.durationSeconds,
            callType = details.callType,
            timestampMillis = details.timestampMillis,
            hardwareId = details.hardwareId,
            callSessionId = null,
        )

        var uploaded = false
        if (directionAllowed && file != null &&
            !ProjectionAudioRecorder.isLikelySilent(file, details.durationSeconds)
        ) {
            uploaded = runCatching { api.uploadRecording(event, file) }.getOrDefault(false)
            if (uploaded) engineStats.recordTier3Success(System.currentTimeMillis())
        }
        file?.let { if (it.exists()) it.delete() }

        if (!uploaded) {
            dbHelper.enqueue(event)
            CallSyncWorker.scheduleNow(applicationContext)
        }
        stopSelfSafely()
    }

    private fun stopSelfSafely() {
        stopForeground(true)
        stopSelf()
    }

    private fun buildNotification(): Notification =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Pype Call Recorder")
            .setContentText("Capturing call audio…")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(CHANNEL_ID, "Call audio capture", NotificationManager.IMPORTANCE_LOW)
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    override fun onDestroy() {
        if (recorder.isActive) recorder.stop()
        jobScope.coroutineContext[Job]?.cancel()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val TAG = "ProjectionCaptureService"
        private const val CHANNEL_ID = "projection_capture_channel"
        private const val NOTIFICATION_ID = 4202
        const val ACTION_START = "com.pypecrm.call_recording_engine.action.PROJECTION_START"
        const val ACTION_STOP = "com.pypecrm.call_recording_engine.action.PROJECTION_STOP"
    }
}
