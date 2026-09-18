package com.pypecrm.call_recording_engine.sync

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import androidx.core.content.ContextCompat
import com.pypecrm.call_recording_engine.data.CallEventDbHelper
import com.pypecrm.call_recording_engine.data.EngineStats
import com.pypecrm.call_recording_engine.data.NativeAuthPrefs
import com.pypecrm.call_recording_engine.debug.EngineDebugLog
import com.pypecrm.call_recording_engine.net.BackendApi
import com.pypecrm.call_recording_engine.net.BulkSyncResult

/** Outcome of one [CallSyncRunner.run] pass — lets a caller (the periodic
 * worker, or a user-triggered manual re-check) report what actually
 * happened instead of assuming success the moment the work was scheduled. */
sealed class SyncOutcome {
    data class Success(val reconciledCount: Int, val syncedCount: Int, val pendingCount: Int) : SyncOutcome()
    data class RateLimited(val reconciledCount: Int, val pendingCount: Int, val retryAfterSeconds: Int) : SyncOutcome()
    data class Failed(val reconciledCount: Int, val pendingCount: Int, val httpCode: Int?, val message: String?) : SyncOutcome()
    /** No usable network right now (per [ConnectivityManager]) — distinct from
     * [Failed] because it's an expected, self-explanatory state (not connected
     * yet), not something that went wrong. The periodic worker never sees
     * this case (WorkManager's own NetworkType.CONNECTED constraint already
     * keeps it from running at all without a network); it's specific to the
     * manual re-check path, which runs inline and has no such gate. */
    data class NoConnection(val reconciledCount: Int, val pendingCount: Int) : SyncOutcome()
    object PermissionMissing : SyncOutcome()
    object NotSignedIn : SyncOutcome()
}

/**
 * The actual reconcile-then-upload mechanics, shared by [CallSyncWorker]
 * (periodic/automatic, self-throttled, reports back to WorkManager) and the
 * user-triggered manual re-check exposed to Dart (immediate, bypasses the
 * client-side cooldown since an explicit tap shouldn't be silently
 * swallowed by it, reports a real [SyncOutcome] instead of a fire-and-forget
 * "scheduled" signal). The server's own rate limit is still respected
 * either way — a bypassed cooldown can still come back as [SyncOutcome.RateLimited].
 */
object CallSyncRunner {

    private const val COOLDOWN_MS = 10 * 60 * 1000L

    suspend fun run(context: Context, authPrefs: NativeAuthPrefs, bypassCooldown: Boolean): SyncOutcome {
        if (!authPrefs.isSignedIn()) return SyncOutcome.NotSignedIn
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALL_LOG)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return SyncOutcome.PermissionMissing
        }

        // Local-only (no network, no rate limit) — always runs regardless
        // of the bulk-sync throttle below, so a call the real-time path
        // missed gets discovered promptly even while an upload is still
        // cooling down. See CallLogReconciler's doc comment.
        val reconciledCount = CallLogReconciler.reconcile(context, authPrefs)

        val dbHelper = CallEventDbHelper.getInstance(context)
        val engineStats = EngineStats(context)
        val now = System.currentTimeMillis()
        if (!bypassCooldown && now < engineStats.nextBulkSyncAllowedAtMillis) {
            return SyncOutcome.Success(reconciledCount, syncedCount = 0, pendingCount = dbHelper.unsyncedEvents().size)
        }

        val pending = dbHelper.unsyncedEvents()
        if (pending.isEmpty()) return SyncOutcome.Success(reconciledCount, syncedCount = 0, pendingCount = 0)

        if (!hasUsableNetwork(context)) {
            return SyncOutcome.NoConnection(reconciledCount, pending.size)
        }

        val api = BackendApi(authPrefs)
        return when (val result = api.bulkSync(pending)) {
            is BulkSyncResult.Success -> {
                // Only clear the entries the server actually confirmed by hardwareId —
                // NOT the whole `pending` batch. A 2xx here can still mean some entries
                // were legitimately skipped/errored server-side; anything not in
                // syncedHardwareIds stays queued and gets retried next time instead of
                // silently vanishing from the local queue.
                val confirmedIds = pending
                    .filter { it.hardwareId != null && it.hardwareId in result.syncedHardwareIds }
                    .map { it.id }
                dbHelper.markSynced(confirmedIds)
                dbHelper.pruneSynced()
                engineStats.recordTier4Success(System.currentTimeMillis(), confirmedIds.size)
                engineStats.nextBulkSyncAllowedAtMillis = System.currentTimeMillis() + COOLDOWN_MS
                val unconfirmed = pending.size - confirmedIds.size
                EngineDebugLog(context).append(
                    "BULK_SYNC_SUCCESS",
                    "${confirmedIds.size} call(s) synced" +
                        if (unconfirmed > 0) ", $unconfirmed still queued (server skipped/errored or had no hardwareId)" else "",
                )
                SyncOutcome.Success(reconciledCount, confirmedIds.size, unconfirmed)
            }
            is BulkSyncResult.RateLimited -> {
                engineStats.nextBulkSyncAllowedAtMillis = System.currentTimeMillis() + result.retryAfterSeconds * 1000L
                EngineDebugLog(context).append(
                    "BULK_SYNC_RATE_LIMITED",
                    "retry in ${result.retryAfterSeconds}s",
                    level = "warn",
                )
                SyncOutcome.RateLimited(reconciledCount, pending.size, result.retryAfterSeconds)
            }
            is BulkSyncResult.Failed -> {
                EngineDebugLog(context).append(
                    "BULK_SYNC_FAILED",
                    "${pending.size} call(s) still pending — httpCode=${result.httpCode} ${result.message.orEmpty()}".trim(),
                    level = "error",
                )
                SyncOutcome.Failed(reconciledCount, pending.size, result.httpCode, result.message)
            }
        }
    }

    /** Mirrors the check WorkManager's own `NetworkType.CONNECTED` constraint
     * makes for the periodic path — this path has no such constraint (it runs
     * inline from a direct method call, not a scheduled job), so without this
     * check a device with no/flaky connectivity would attempt the request
     * anyway and surface a raw, unhelpful exception instead of a clear
     * "not connected" outcome. `NET_CAPABILITY_VALIDATED` catches the "on
     * WiFi but no real internet" case (captive portal, router with no
     * upstream), not just "no network at all". */
    private fun hasUsableNetwork(context: Context): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return true
        val network = cm.activeNetwork ?: return false
        val capabilities = cm.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
            capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    }
}
