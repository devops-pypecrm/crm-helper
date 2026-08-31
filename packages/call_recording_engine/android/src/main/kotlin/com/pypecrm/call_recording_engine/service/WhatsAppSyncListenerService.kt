package com.pypecrm.call_recording_engine.service

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.pypecrm.call_recording_engine.data.EngineStats
import com.pypecrm.call_recording_engine.data.NativeAuthPrefs
import com.pypecrm.call_recording_engine.data.WhatsAppQueueStore
import com.pypecrm.call_recording_engine.net.BackendApi
import com.pypecrm.call_recording_engine.net.WhatsAppSyncResult
import com.pypecrm.call_recording_engine.sync.WhatsAppSyncWorker
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Reads inbound WhatsApp notification previews — contact name/number and the
 * message text as shown in the notification banner, never the full chat
 * history, which this service has no access to — and logs them to the CRM
 * as an activity against the matching lead/contact, so a field rep's
 * WhatsApp replies show up in the timeline without manual entry.
 *
 * Ported 1:1 (dedup logic included) from Dad-frontend/android's old
 * WebView-wrapper app (`WhatsAppNotificationListener.kt`), moved here
 * because `BIND_NOTIFICATION_LISTENER_SERVICE` — reading another app's
 * notification content — is exactly the kind of sensitive permission
 * Google Play's Notification Access policy scrutinizes heavily and can get
 * an app rejected/suspended over. This app is sideloaded and never
 * Play-distributed (see Dad-call-recorder's AndroidManifest.xml), so it can
 * carry that risk; Dad-mobile (the Play Store app) must never carry this
 * service.
 *
 * Gated server-side by `Organisation.whatsAppScrapingEnabled`
 * (Dad-backend's `logExternalMessage` controller) — this service always
 * attempts to sync once the user has granted "Notification access" in
 * system Settings (see `NotificationListenerUtils.isWhatsAppListenerEnabled`);
 * if the org has the feature turned off, the backend just responds
 * `{ success: false }` and nothing is queued or retried. No separate
 * client-side on/off flag is needed on top of that.
 */
class WhatsAppSyncListenerService : NotificationListenerService() {

    private var lastMessage: String? = null
    private var lastContact: String? = null
    private var lastSyncAtMillis: Long = 0

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName
        if (packageName != PACKAGE_WHATSAPP && packageName != PACKAGE_WHATSAPP_BUSINESS) return

        val extras = sbn.notification.extras
        val contact = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val message = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()

        // Ignore system/summary notifications, calls, or empty data.
        if (contact.isNullOrEmpty() || message.isNullOrEmpty()) return
        if (contact == "WhatsApp" || contact == "WhatsApp Business") return
        if (message.contains("Checking for new messages") || message.contains("📷")) return

        val now = System.currentTimeMillis()
        // Dedup: WhatsApp reposts the same notification (e.g. on an unrelated
        // status update) — ignore an identical contact+message pair seen
        // within the last 10 seconds rather than logging it twice.
        if (contact == lastContact && message == lastMessage && (now - lastSyncAtMillis < DEDUP_WINDOW_MS)) {
            return
        }
        lastContact = contact
        lastMessage = message
        lastSyncAtMillis = now

        syncMessage(contact, message)
    }

    private fun syncMessage(contact: String, message: String) {
        val authPrefs = NativeAuthPrefs(applicationContext)
        if (!authPrefs.isSignedIn()) return

        CoroutineScope(Dispatchers.IO).launch {
            val api = BackendApi(authPrefs)
            when (api.syncWhatsAppMessage(contact, message)) {
                WhatsAppSyncResult.Success ->
                    EngineStats(applicationContext).recordWhatsAppSync(System.currentTimeMillis())
                // Org turned it off, or the token is stale — neither is worth
                // queuing for retry (see BackendApi.syncWhatsAppMessage's doc).
                WhatsAppSyncResult.Disabled, WhatsAppSyncResult.AuthFailed -> Unit
                WhatsAppSyncResult.Failed -> {
                    Log.w(TAG, "Sync failed, queuing for retry")
                    WhatsAppQueueStore(applicationContext).enqueue(contact, message)
                    WhatsAppSyncWorker.scheduleNow(applicationContext)
                }
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        // No action needed on removal.
    }

    companion object {
        private const val TAG = "WhatsAppSyncListener"
        private const val PACKAGE_WHATSAPP = "com.whatsapp"
        private const val PACKAGE_WHATSAPP_BUSINESS = "com.whatsapp.w4b"
        private const val DEDUP_WINDOW_MS = 10_000L
    }
}
