package com.pypecrm.call_recording_engine.sync

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.pypecrm.call_recording_engine.data.EngineStats
import com.pypecrm.call_recording_engine.data.NativeAuthPrefs
import com.pypecrm.call_recording_engine.data.WhatsAppQueueStore
import com.pypecrm.call_recording_engine.net.BackendApi
import com.pypecrm.call_recording_engine.net.WhatsAppSyncResult
import java.util.concurrent.TimeUnit

/**
 * Drains [WhatsAppQueueStore] — messages that failed to sync immediately
 * from [com.pypecrm.call_recording_engine.service.WhatsAppSyncListenerService]
 * due to a transient/network error. Mirrors [CallSyncWorker]'s retry
 * pattern, but unlike Tier 4's bulk-sync endpoint there is no server-side
 * rate limit on `/android/whatsapp/sync` (it's a single-row POST, not a
 * bulk import), so each pending message is sent individually here rather
 * than batched.
 */
class WhatsAppSyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val authPrefs = NativeAuthPrefs(applicationContext)
        if (!authPrefs.isSignedIn()) return Result.success()

        val queueStore = WhatsAppQueueStore(applicationContext)
        val pending = queueStore.getAll()
        if (pending.isEmpty()) return Result.success()

        val api = BackendApi(authPrefs)
        val stats = EngineStats(applicationContext)
        val stillPending = mutableListOf<Pair<String, String>>()
        var anyTransientFailure = false

        for ((phoneNumber, messageText) in pending) {
            when (api.syncWhatsAppMessage(phoneNumber, messageText)) {
                WhatsAppSyncResult.Success -> stats.recordWhatsAppSync(System.currentTimeMillis())
                // Org turned it off, or the token is stale — retrying won't
                // help either, so these are dropped rather than re-queued.
                WhatsAppSyncResult.Disabled, WhatsAppSyncResult.AuthFailed -> Unit
                WhatsAppSyncResult.Failed -> {
                    stillPending += phoneNumber to messageText
                    anyTransientFailure = true
                }
            }
        }

        queueStore.replaceAll(stillPending)
        return if (anyTransientFailure) Result.retry() else Result.success()
    }

    companion object {
        private const val WORK_NAME = "call_recording_engine_whatsapp_sync"
        private const val PERIODIC_WORK_NAME = "call_recording_engine_whatsapp_sync_periodic"

        private fun networkConstraints() =
            Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

        /** Fired right after a sync attempt fails with something queued. */
        fun scheduleNow(context: Context) {
            val request = OneTimeWorkRequestBuilder<WhatsAppSyncWorker>()
                .setConstraints(networkConstraints())
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
                .build()
            WorkManager.getInstance(context)
                .enqueueUniqueWork(WORK_NAME, ExistingWorkPolicy.REPLACE, request)
        }

        /** Periodic safety net so a message queued while offline still gets
         * swept up even if no later notification ever triggers [scheduleNow]
         * — same reasoning as [CallSyncWorker.schedulePeriodic]. */
        fun schedulePeriodic(context: Context) {
            val request = PeriodicWorkRequestBuilder<WhatsAppSyncWorker>(15, TimeUnit.MINUTES)
                .setConstraints(networkConstraints())
                .build()
            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(PERIODIC_WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, request)
        }
    }
}
