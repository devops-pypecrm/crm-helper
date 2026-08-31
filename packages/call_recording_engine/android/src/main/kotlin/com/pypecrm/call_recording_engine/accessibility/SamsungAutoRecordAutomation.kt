package com.pypecrm.call_recording_engine.accessibility

import android.accessibilityservice.AccessibilityService
import android.content.pm.PackageManager
import android.view.accessibility.AccessibilityNodeInfo
import com.pypecrm.call_recording_engine.debug.EngineDebugLog
import kotlinx.coroutines.delay

/**
 * Best-effort UI automation that opens Samsung's stock Phone app and
 * enables its built-in "auto record calls" setting, so the OEM's own
 * privileged dialer produces the recording (sidestepping the
 * `CAPTURE_AUDIO_OUTPUT` wall entirely — see Tier 1/2's doc comments on why
 * no third-party app, default-dialer or not, can tap the telephony audio
 * stream directly) and Tier 0's [NativeRecordingScanner] then just needs to
 * find the resulting file after each call.
 *
 * IMPORTANT — this was written without access to real Samsung One UI
 * hardware, so the exact screen text/layout below is a best guess from
 * public documentation, not something verified against a device.
 * Samsung's own screen text also varies by One UI version, region, and
 * language, and the "auto record calls" toggle itself has reportedly been
 * removed entirely on some regional builds for legal/consent-law reasons —
 * this automation cannot know that in advance, only discover it by failing
 * to find the toggle. Every step logs what it actually saw on screen
 * BEFORE trying to act on it, specifically so a failed attempt can be
 * diagnosed and this file iterated on from real-device log output, the
 * same real-device iterate loop already used elsewhere in this project
 * (see e.g. CallLogLookup's history) — never assume a step worked just
 * because a click didn't throw.
 */
object SamsungAutoRecordAutomation {

    private const val DIALER_PACKAGE = "com.samsung.android.dialer"
    private const val WINDOW_WAIT_TIMEOUT_MS = 6_000L
    private const val WINDOW_POLL_INTERVAL_MS = 300L

    // Candidate visible-text strings for each screen, tried in order. Only
    // the first-matching candidate per step is used — logged either way.
    private val OVERFLOW_MENU_CANDIDATES = listOf("More options", "More", "Menu")
    private val SETTINGS_CANDIDATES = listOf("Settings")
    private val CALL_RECORDING_CANDIDATES = listOf("Call recording", "Record calls", "Recording")
    private val AUTO_RECORD_TOGGLE_CANDIDATES =
        listOf("Auto recording", "Record calls automatically", "Auto record calls", "Automatic recording")

    suspend fun attempt(service: AccessibilityService, log: EngineDebugLog) {
        log.append("AUTO_RECORD_SETUP_STARTED", "target=Samsung One UI")

        if (!isPackageInstalled(service, DIALER_PACKAGE)) {
            log.append("AUTO_RECORD_SETUP_STOPPED", "Samsung dialer package not found on this device — not a Samsung phone, or a different package name on this model/region")
            return
        }

        val launchIntent = service.packageManager.getLaunchIntentForPackage(DIALER_PACKAGE)
        if (launchIntent == null) {
            log.append("AUTO_RECORD_SETUP_STOPPED", "Samsung dialer package present but has no launchable activity")
            return
        }
        service.startActivity(launchIntent)
        log.append("AUTO_RECORD_SETUP_STEP", "Launched $DIALER_PACKAGE, waiting for its window")

        if (!awaitWindow(service, DIALER_PACKAGE, log)) {
            log.append("AUTO_RECORD_SETUP_FAILED", "Samsung dialer window never appeared within ${WINDOW_WAIT_TIMEOUT_MS}ms")
            return
        }

        if (!findAndClick(service, log, "overflow menu", OVERFLOW_MENU_CANDIDATES)) return
        delay(800L)
        if (!findAndClick(service, log, "settings entry", SETTINGS_CANDIDATES)) return
        delay(800L)
        if (!findAndClick(service, log, "call recording entry", CALL_RECORDING_CANDIDATES)) return
        delay(800L)

        val toggle = findFirstMatch(service.rootInActiveWindow, AUTO_RECORD_TOGGLE_CANDIDATES)
        if (toggle == null) {
            log.append(
                "AUTO_RECORD_SETUP_FAILED",
                "auto-record toggle not found — texts on screen: ${dumpVisibleTexts(service.rootInActiveWindow)}",
            )
            return
        }
        val switchNode = findClickableSelfOrAncestor(toggle)
        if (switchNode == null) {
            log.append("AUTO_RECORD_SETUP_FAILED", "found toggle text '${toggle.text}' but no clickable node containing it")
            return
        }
        if (switchNode.isChecked) {
            log.append("AUTO_RECORD_SETUP_SUCCESS", "toggle already enabled")
            return
        }
        switchNode.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        delay(500L)
        val refreshed = findFirstMatch(service.rootInActiveWindow, AUTO_RECORD_TOGGLE_CANDIDATES)
        val nowChecked = refreshed?.let { findClickableSelfOrAncestor(it)?.isChecked } ?: false
        if (nowChecked) {
            log.append("AUTO_RECORD_SETUP_SUCCESS", "toggle clicked and observed checked afterward")
        } else {
            // Never claim success from the click not throwing — only from
            // the observed post-click state, same discipline as the
            // conference-merge POC's outcome classification.
            log.append("AUTO_RECORD_SETUP_FAILED", "clicked toggle but it did not report checked afterward")
        }
    }

    private suspend fun awaitWindow(service: AccessibilityService, expectedPackage: String, log: EngineDebugLog): Boolean {
        val deadline = System.currentTimeMillis() + WINDOW_WAIT_TIMEOUT_MS
        while (System.currentTimeMillis() < deadline) {
            val root = service.rootInActiveWindow
            if (root != null && root.packageName?.toString() == expectedPackage) {
                log.append("AUTO_RECORD_SETUP_STEP", "window ready — texts visible: ${dumpVisibleTexts(root)}")
                return true
            }
            delay(WINDOW_POLL_INTERVAL_MS)
        }
        return false
    }

    private suspend fun findAndClick(
        service: AccessibilityService,
        log: EngineDebugLog,
        stepName: String,
        candidates: List<String>,
    ): Boolean {
        val root = service.rootInActiveWindow
        val match = findFirstMatch(root, candidates)
        if (match == null) {
            log.append(
                "AUTO_RECORD_SETUP_FAILED",
                "could not find $stepName (tried: ${candidates.joinToString()}) — texts on screen: ${dumpVisibleTexts(root)}",
            )
            return false
        }
        val clickable = findClickableSelfOrAncestor(match)
        if (clickable == null) {
            log.append("AUTO_RECORD_SETUP_FAILED", "found $stepName text '${match.text}' but no clickable ancestor")
            return false
        }
        clickable.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        log.append("AUTO_RECORD_SETUP_STEP", "clicked $stepName ('${match.text}')")
        return true
    }

    private fun findFirstMatch(root: AccessibilityNodeInfo?, candidates: List<String>): AccessibilityNodeInfo? {
        if (root == null) return null
        for (candidate in candidates) {
            val matches = root.findAccessibilityNodeInfosByText(candidate)
            val exact = matches.firstOrNull { it.text?.toString()?.equals(candidate, ignoreCase = true) == true }
            if (exact != null) return exact
        }
        return null
    }

    private fun findClickableSelfOrAncestor(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        var current: AccessibilityNodeInfo? = node
        var depth = 0
        while (current != null && depth < MAX_ANCESTOR_DEPTH) {
            if (current.isClickable) return current
            current = current.parent
            depth++
        }
        return null
    }

    /** Small, depth-limited text dump for diagnostics — not a general
     * tree-walk utility, just enough to see what a failed step actually had
     * on screen when read back from [EngineDebugLog]. */
    private fun dumpVisibleTexts(root: AccessibilityNodeInfo?, depth: Int = 0, maxDepth: Int = 6): String {
        if (root == null || depth > maxDepth) return ""
        val texts = mutableListOf<String>()
        root.text?.toString()?.takeIf { it.isNotBlank() }?.let { texts.add(it) }
        for (i in 0 until root.childCount) {
            root.getChild(i)?.let { child ->
                val childText = dumpVisibleTexts(child, depth + 1, maxDepth)
                if (childText.isNotBlank()) texts.add(childText)
            }
        }
        return texts.joinToString(" | ")
    }

    private fun isPackageInstalled(service: AccessibilityService, packageName: String): Boolean =
        try {
            service.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }

    private const val MAX_ANCESTOR_DEPTH = 8
}
