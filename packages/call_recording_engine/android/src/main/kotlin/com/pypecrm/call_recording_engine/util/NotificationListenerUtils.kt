package com.pypecrm.call_recording_engine.util

import android.content.Context
import androidx.core.app.NotificationManagerCompat

object NotificationListenerUtils {
    /**
     * Whether the user has granted this app "Notification access" in system
     * Settings — required for [com.pypecrm.call_recording_engine.service.WhatsAppSyncListenerService]
     * to receive [android.service.notification.StatusBarNotification] callbacks
     * at all. Mirrors [AccessibilityUtils.isCallRecordingServiceEnabled]'s
     * role for Tier 2: Android does not let an app grant this to itself, so
     * this is check-only — see [com.pypecrm.call_recording_engine.CallRecordingEnginePlugin]'s
     * `openNotificationListenerSettings` for the action half.
     */
    fun isWhatsAppListenerEnabled(context: Context): Boolean =
        NotificationManagerCompat.getEnabledListenerPackages(context).contains(context.packageName)
}
