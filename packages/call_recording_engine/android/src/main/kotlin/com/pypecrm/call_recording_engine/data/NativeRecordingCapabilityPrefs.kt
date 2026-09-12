package com.pypecrm.call_recording_engine.data

import android.content.Context

/**
 * Tracks whether THIS device ever actually produces a Tier 0 native
 * call-recording file (some OEM dialers auto-record; most don't).
 *
 * Without this, [com.pypecrm.call_recording_engine.service.CallMonitorService.pollTier0]
 * always ran its full 9-attempt / ~18s poll after every single call, even on
 * a device that has never once produced a match — real, measured user
 * impact: the helper app's foreground service kept doing active background
 * work for 18s after every hangup for no benefit on those devices, the
 * window a rep is most likely to immediately try something else (e.g.
 * messaging the lead they just called).
 *
 * Once [consecutiveMissedCalls] reaches [UNSUPPORTED_THRESHOLD] with zero
 * matches in between, [isLikelyUnsupported] flips true and the poll is cut
 * down to [SHORT_POLL_ATTEMPTS]. A single match at any point resets the
 * counter and un-flags it — some OEMs only record certain call types
 * (e.g. only cellular, not VoIP), so "never seen one" should stay a live,
 * revisable judgement rather than a permanent one-way switch.
 */
class NativeRecordingCapabilityPrefs(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private var consecutiveMissedCalls: Int
        get() = prefs.getInt(KEY_CONSECUTIVE_MISSES, 0)
        set(value) = prefs.edit().putInt(KEY_CONSECUTIVE_MISSES, value).apply()

    val isLikelyUnsupported: Boolean
        get() = consecutiveMissedCalls >= UNSUPPORTED_THRESHOLD

    /** Call once per completed call, after the full poll loop finishes. */
    fun recordCallOutcome(matchFound: Boolean) {
        consecutiveMissedCalls = if (matchFound) 0 else consecutiveMissedCalls + 1
    }

    companion object {
        private const val PREFS_NAME = "call_recording_engine_native_capability"
        private const val KEY_CONSECUTIVE_MISSES = "consecutive_missed_calls"

        /** Calls with zero Tier 0 matches before concluding this device
         * doesn't support it — high enough that a couple of unlucky early
         * calls (OEM's own recorder still finishing, a genuinely short
         * call, etc.) can't misclassify a device that actually does work. */
        private const val UNSUPPORTED_THRESHOLD = 5

        /** Poll attempts once a device is flagged unsupported — kept at 2
         * (not 0) rather than skipping entirely, since a match is still
         * technically possible and [recordCallOutcome] needs a real chance
         * to un-flag a device if something changes (an OS update, the user
         * enabling their OEM's auto-record setting, etc). */
        const val SHORT_POLL_ATTEMPTS = 2
    }
}
