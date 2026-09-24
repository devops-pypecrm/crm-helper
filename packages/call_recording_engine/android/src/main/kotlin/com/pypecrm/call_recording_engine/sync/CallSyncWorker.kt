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
import androidx.work.OutOfQuotaPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.pypecrm.call_recording_engine.data.NativeAuthPrefs
import java.util.concurrent.TimeUnit

/**
 * Tier 4's actual sync implementation, and the offline-recovery path for
 * calls whose Tier 0 upload couldn't run at call-end (no network). Always
 * sends the ENTIRE unsynced queue in one `POST /api/android/bulk-sync` call
 * — never per-event — because the server rate-limits that endpoint to
 * 1 request/user/30sec (Dad-backend/src/routes/androidRoutes.ts — shortened
 * from an original 10min).
 * Self-throttles client-side against that same limit via [EngineStats] so a
 * device that just synced doesn't even attempt a run it knows will 429.
 */
class CallSyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val authPrefs = NativeAuthPrefs(applicationContext)
        if (!authPrefs.isSignedIn()) return Result.success() // nothing to do, not logged in

        // bypassCooldown=false — the periodic/automatic path is exactly
        // what the self-throttle exists to protect; see CallSyncRunner's
        // doc comment for why a manual re-check bypasses it instead.
        val outcome = CallSyncRunner.run(applicationContext, authPrefs, bypassCooldown = false)
        if (outcome is SyncOutcome.Success) {
            Log.d(TAG, "Sync pass done — reconciled=${outcome.reconciledCount} synced=${outcome.syncedCount}")
        }

        // Runs after bulk-sync so a just-logged BULK_SYNC_* event goes out
        // in the same upload pass, not delayed to the next tick — best
        // effort, never affects this worker's own success/retry outcome.
        HelperLogUploader.upload(applicationContext, authPrefs)

        return when (outcome) {
            is SyncOutcome.RateLimited, is SyncOutcome.Failed -> Result.retry()
            else -> Result.success()
        }
    }

    companion object {
        private const val TAG = "CallSyncWorker"
        private const val WORK_NAME = "call_recording_engine_sync"
        private const val PERIODIC_WORK_NAME = "call_recording_engine_sync_periodic"

        private fun networkConstraints() =
            Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

        /** Fired right after a call ends with something queued for Tier 4,
         * and as an immediate retry trigger once connectivity returns.
         * `setExpedited()` is the actual fix for the real-world "call count
         * only updates by evening" complaint: a plain (non-expedited)
         * OneTimeWorkRequest is fully subject to Doze/App Standby deferral,
         * which can genuinely delay execution for hours on an idle device —
         * expedited work runs near-immediately instead (falling back to a
         * regular request, per [OutOfQuotaPolicy], only if the app has
         * exhausted its expedited-job quota for the period). This doesn't
         * replace battery-optimization exemption as a reliability measure
         * (a user who never grants it can still get throttled elsewhere),
         * but it removes the single biggest source of multi-hour lag for
         * everyone else. */
        fun scheduleNow(context: Context) {
            val request = OneTimeWorkRequestBuilder<CallSyncWorker>()
                .setConstraints(networkConstraints())
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
                .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
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
