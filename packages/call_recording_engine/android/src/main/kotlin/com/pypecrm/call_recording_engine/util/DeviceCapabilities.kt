package com.pypecrm.call_recording_engine.util

import android.app.ActivityManager
import android.content.Context

/**
 * Gates the live-capture tiers (1/2/3 — all of which force
 * MODE_IN_COMMUNICATION/speakerphone and hold an in-call audio source for
 * the whole call) off on hardware too weak to safely run them alongside an
 * active call. Reported real-world failures (calls failing to place/lagging
 * to the point of being unusable) came from 2GB-class devices — Android's
 * own [ActivityManager.isLowRamDevice] is an OEM-set flag that many budget
 * devices leave false even at 2-3GB, so it's checked as a fast path but
 * [totalMem] is the authoritative signal.
 */
object DeviceCapabilities {

    // Comfortably above the reported failing devices (realme C11 2021 at
    // 2GB) and below typical mid-range RAM (4GB+) — see class doc comment.
    private const val LOW_RAM_THRESHOLD_BYTES = 3L * 1024 * 1024 * 1024

    fun isLowRam(context: Context): Boolean {
        val activityManager =
            context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager ?: return false
        if (activityManager.isLowRamDevice) return true
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        return memoryInfo.totalMem in 1 until LOW_RAM_THRESHOLD_BYTES
    }
}
