package com.pypecrm.call_recording_engine.sync

import android.content.Context
import android.util.Log
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
import com.pypecrm.call_recording_engine.data.CallEventDbHelper
import com.pypecrm.call_recording_engine.data.EngineStats
import com.pypecrm.call_recording_engine.data.NativeAuthPrefs
import com.pypecrm.call_recording_engine.debug.EngineDebugLog
import com.pypecrm.call_recording_engine.net.BackendApi
import com.pypecrm.call_recording_engine.net.BulkSyncResult
import java.util.concurrent.TimeUnit

/**
 * Tier 4's actual sync implementation, and the offline-recovery path for
 * calls whose Tier 0 upload couldn't run at call-end (no network). Always
 * sends the ENTIRE unsynced queue in one `POST /api/android/bulk-sync` call
 * — never per-event — because the server hard rate-limits that endpoint to
 * 1 request/user/10min (Dad-backend/src/routes/androidRoutes.ts).
 * Self-throttles client-side against that same limit via [EngineStats] so a
 * device that just synced doesn't even attempt a run it knows will 429.
 */
class CallSyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val authPrefs = NativeAuthPrefs(applicationContext)
        if (!authPrefs.isSignedIn()) return Result.success() // nothing to do, not logged in

        // Local-only (no network, no rate limit) — runs on every periodic
        // tick regardless of the bulk-sync throttle below, so a call the
        // real-time path missed gets discovered promptly even while an
        // upload is still cooling down. See CallLogReconciler's doc
        // comment for why this can't just be part of the real-time path.
        CallLogReconciler.reconcile(applicationContext, authPrefs)

        val engineStats = EngineStats(applicationContext)
        val now = System.currentTimeMillis()
        if (now < engineStats.nextBulkSyncAllowedAtMillis) {
            Log.d(TAG, "Self-throttled — next bulk-sync allowed at ${engineStats.nextBulkSyncAllowedAtMillis}")
            return Result.success()
        }

        val dbHelper = CallEventDbHelper.getInstance(applicationContext)
        val pending = dbHelper.unsyncedEvents()
        val workResult = if (pending.isEmpty()) {
            Result.success()
        } else {
            val api = BackendApi(authPrefs)
            when (val result = api.bulkSync(pending)) {
                is BulkSyncResult.Success -> {
                    dbHelper.markSynced(pending.map { it.id })
                    dbHelper.pruneSynced()
                    engineStats.recordTier4Success(System.currentTimeMillis(), result.count)
                    engineStats.nextBulkSyncAllowedAtMillis = System.currentTimeMillis() + COOLDOWN_MS
                    EngineDebugLog(applicationContext).append("BULK_SYNC_SUCCESS", "${result.count} call(s) synced")
                    Result.success()
                }
                is BulkSyncResult.RateLimited -> {
                    engineStats.nextBulkSyncAllowedAtMillis =
                        System.currentTimeMillis() + result.retryAfterSeconds * 1000L
                    EngineDebugLog(applicationContext).append(
                        "BULK_SYNC_RATE_LIMITED",
                        "retry in ${result.retryAfterSeconds}s",
                        level = "warn",
                    )
                    Result.retry()
                }
                BulkSyncResult.Failed -> {
                    EngineDebugLog(applicationContext).append(
                        "BULK_SYNC_FAILED",
                        "${pending.size} call(s) still pending",
                        level = "error",
                    )
                    Result.retry()
                }
            }
        }

        // Runs after bulk-sync so a just-logged BULK_SYNC_* event goes out
        // in the same upload pass, not delayed to the next tick — best
        // effort, never affects this worker's own success/retry outcome.
        HelperLogUploader.upload(applicationContext, authPrefs)

        return workResult
    }

    companion object {
        private const val TAG = "CallSyncWorker"
        private const val WORK_NAME = "call_recording_engine_sync"
        private const val PERIODIC_WORK_NAME = "call_recording_engine_sync_periodic"
        private const val COOLDOWN_MS = 10 * 60 * 1000L

        private fun networkConstraints() =
            Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

        /** Fired right after a call ends with something queued for Tier 4,
         * and as an immediate retry trigger once connectivity returns. */
        fun scheduleNow(context: Context) {
            val request = OneTimeWorkRequestBuilder<CallSyncWorker>()
                .setConstraints(networkConstraints())
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
                .build()
            WorkManager.getInstance(context)
                .enqueueUniqueWork(WORK_NAME, ExistingWorkPolicy.REPLACE, request)
        }

        /** Periodic safety net (WorkManager's minimum period is 15 minutes)
         * so a call queued while offline at call-end still gets swept up
         * even if no later call ever triggers [scheduleNow] — this is the
         * actual offline-recovery guarantee from the plan's Phase 1
         * verification checklist. */
        fun schedulePeriodic(context: Context) {
            val request = PeriodicWorkRequestBuilder<CallSyncWorker>(15, TimeUnit.MINUTES)
                .setConstraints(networkConstraints())
                .build()
            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(PERIODIC_WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, request)
        }
    }
}
