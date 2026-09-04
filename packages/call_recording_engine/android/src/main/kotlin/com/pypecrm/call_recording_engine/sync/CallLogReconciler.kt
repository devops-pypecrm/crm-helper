package com.pypecrm.call_recording_engine.sync

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.CallLog
import android.util.Log
import androidx.core.content.ContextCompat
import com.pypecrm.call_recording_engine.data.CallEventDbHelper
import com.pypecrm.call_recording_engine.data.CallLogReconcilePrefs
import com.pypecrm.call_recording_engine.data.CallSettingsCache
import com.pypecrm.call_recording_engine.data.NativeAuthPrefs
import com.pypecrm.call_recording_engine.data.PendingCallEvent
import com.pypecrm.call_recording_engine.debug.EngineDebugLog
import com.pypecrm.call_recording_engine.net.BackendApi
import com.pypecrm.call_recording_engine.scanner.NativeRecordingScanner

/**
 * Catches up on calls the real-time capture path (CallStateReceiver +
 * CallLogLookup) never saw at all — an OEM battery manager killing the
 * background service mid-session, a missed broadcast, the app not having
 * been running yet on first install, etc. That path only ever reacts to a
 * *live* phone-state change; if it never fires for a given call, nothing
 * else in this engine goes back and notices later. This does: it reads the
 * system CallLog directly (the OS's own record, written regardless of
 * whether our app was even alive at the time) for everything since the
 * last reconciliation, and queues up anything not already known.
 *
 * Also attempts Tier 0 recovery for each backfilled call — not just
 * metadata. The live path's [CallMonitorService] only ever calls
 * [NativeRecordingScanner] right after a call-end it actually detected; a
 * call this reconciler is backfilling means that detection never happened,
 * so nothing would otherwise have gone looking for a native-recorder file
 * either, even when the phone genuinely recorded the call. Unlike the live
 * path's short poll (a few seconds, for OEMs that finalize the file a
 * little late), this only needs a single query: by the time reconciliation
 * runs, the call is already well in the past, so the file — if the OEM's
 * recorder made one — has had plenty of time to finish writing.
 *
 * Safe to run repeatedly / to re-enqueue a call that was actually already
 * synced via the real-time path: the backend dedupes incoming syncs by
 * `hardwareId` (see Dad-backend's `syncCallLogs`), and this uses the exact
 * same convention `CallLogLookup` already does — the CallLog row's own
 * stable `_ID` as `hardwareId` — so a re-sent already-known call just
 * "heals" the existing server-side record instead of duplicating it. That
 * also makes it safe for the Tier 0 upload attempt below to fall back to a
 * metadata-only enqueue on failure without risking a duplicate row.
 *
 * Uses no permission beyond `READ_CALL_LOG`, already required (and already
 * granted, or this whole engine wouldn't be running) for Tier 0/4 — reading
 * older CallLog rows needs nothing more than reading recent ones does.
 */
object CallLogReconciler {
    private const val TAG = "CallLogReconciler"

    /** Returns how many previously-unseen calls were recovered (audio or
     * metadata-only combined). */
    fun reconcile(context: Context, authPrefs: NativeAuthPrefs): Int {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALL_LOG)
            != PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "READ_CALL_LOG not granted — skipping reconciliation")
            return 0
        }

        val prefs = CallLogReconcilePrefs(context)
        val since = prefs.lastReconciledAtMillis
        val dbHelper = CallEventDbHelper.getInstance(context)
        val api = BackendApi(authPrefs)
        val settingsCache = CallSettingsCache(context)
        settingsCache.refreshIfStale(api)

        var queued = 0
        var tier0Recovered = 0
        var newestSeen = since

        try {
            context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.DURATION,
                    CallLog.Calls.TYPE,
                    CallLog.Calls.DATE,
                    CallLog.Calls._ID,
                ),
                "${CallLog.Calls.DATE} > ?",
                arrayOf(since.toString()),
                // No `LIMIT` embedded here either — same OEM CallLog
                // provider quirk `CallLogLookup` already works around.
                "${CallLog.Calls.DATE} ASC",
            )?.use { cursor ->
                val numberCol = cursor.getColumnIndexOrThrow(CallLog.Calls.NUMBER)
                val durationCol = cursor.getColumnIndexOrThrow(CallLog.Calls.DURATION)
                val typeCol = cursor.getColumnIndexOrThrow(CallLog.Calls.TYPE)
                val dateCol = cursor.getColumnIndexOrThrow(CallLog.Calls.DATE)
                val idCol = cursor.getColumnIndexOrThrow(CallLog.Calls._ID)

                while (cursor.moveToNext()) {
                    val date = cursor.getLong(dateCol)
                    val rowId = cursor.getLong(idCol)
                    val typeInt = cursor.getInt(typeCol)
                    val typeStr = typeToString(typeInt)
                    val durationSecs = cursor.getInt(durationCol)
                    val phoneNumber = cursor.getString(numberCol) ?: ""

                    if (typeStr == "UNKNOWN") {
                        // See CallLogLookup's identical check — an OEM
                        // proprietary CallLog TYPE value outside Android's
                        // documented set. Logging the raw int is the only
                        // way to find out what it actually was.
                        Log.w(TAG, "Unrecognized CallLog TYPE=$typeInt for row $rowId")
                        EngineDebugLog(context).append(
                            "CALL_LOG_UNKNOWN_TYPE",
                            "CallLog TYPE=$typeInt not recognized (row $rowId)",
                            level = "warn",
                        )
                    }

                    val event = PendingCallEvent(
                        phoneNumber = phoneNumber,
                        durationSeconds = durationSecs,
                        callType = typeStr,
                        timestampMillis = date,
                        // Same convention as CallLogLookup: the CallLog
                        // row's own stable _ID. BackendApi namespaces
                        // this per-user before upload, matching what
                        // the real-time path already sends, so the
                        // backend's own dedup treats them identically.
                        hardwareId = rowId.toString(),
                        callSessionId = null,
                    )

                    // A 0-duration call was never connected, so there is
                    // nothing to find; respect the same org-level
                    // inbound/outbound recording-consent gate the live path
                    // enforces — this reconciler must never upload audio a
                    // call-recording-disabled org didn't opt into either.
                    // When the direction itself is unknown (an OEM CallLog
                    // TYPE value outside the handled set — see the
                    // CALL_LOG_UNKNOWN_TYPE log above), `typeStr == "OUTGOING"`
                    // being false must NOT silently resolve to "check the
                    // inbound flag" for what might really be an outgoing
                    // call: require BOTH directions to be allowed instead,
                    // so an ambiguous call is never recorded on the strength
                    // of the wrong direction's consent setting.
                    val directionAllowed = when (typeStr) {
                        "OUTGOING" -> settingsCache.isDirectionAllowed(true)
                        "INCOMING" -> settingsCache.isDirectionAllowed(false)
                        else -> settingsCache.isDirectionAllowed(true) && settingsCache.isDirectionAllowed(false)
                    }
                    val canAttemptTier0 = durationSecs > 0 && phoneNumber.isNotBlank() && directionAllowed

                    var recoveredAudio = false
                    if (canAttemptTier0) {
                        val file = NativeRecordingScanner.scanOnce(context, phoneNumber, date)
                        if (file != null) {
                            recoveredAudio = try {
                                api.uploadRecording(event, file)
                            } catch (e: Exception) {
                                Log.w(TAG, "Tier 0 recovery upload failed for reconciled call", e)
                                false
                            } finally {
                                file.delete()
                            }
                            if (recoveredAudio) tier0Recovered++
                        }
                    }

                    if (!recoveredAudio) {
                        dbHelper.enqueue(event)
                    }
                    queued++
                    if (date > newestSeen) newestSeen = date
                }
            }
        } catch (e: Exception) {
            // Best-effort — a query failure here must not crash anything
            // that scheduled this; the watermark stays where it was, so
            // the next run just retries the same window.
            Log.e(TAG, "CallLog reconciliation query failed", e)
            return queued
        }

        if (newestSeen > since) {
            prefs.lastReconciledAtMillis = newestSeen
        }
        if (queued > 0) {
            Log.i(TAG, "Reconciled $queued call(s) not previously captured ($tier0Recovered with recovered audio)")
            EngineDebugLog(context).append(
                "CALL_LOG_RECONCILED",
                "queued $queued call(s) not seen by the real-time path ($tier0Recovered recovered with audio)",
            )
        }
        return queued
    }

    private fun typeToString(typeInt: Int): String = when (typeInt) {
        CallLog.Calls.INCOMING_TYPE -> "INCOMING"
        CallLog.Calls.OUTGOING_TYPE -> "OUTGOING"
        CallLog.Calls.MISSED_TYPE -> "MISSED"
        CallLog.Calls.VOICEMAIL_TYPE -> "MISSED" // no distinct backend bucket for voicemail
        CallLog.Calls.REJECTED_TYPE -> "REJECTED"
        CallLog.Calls.BLOCKED_TYPE -> "BLOCKED"
        CallLog.Calls.ANSWERED_EXTERNALLY_TYPE -> "INCOMING" // answered on a linked device — still inbound
        else -> "UNKNOWN"
    }
}
