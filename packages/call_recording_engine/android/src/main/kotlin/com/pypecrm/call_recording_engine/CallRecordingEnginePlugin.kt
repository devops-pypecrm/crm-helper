package com.pypecrm.call_recording_engine

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.pypecrm.call_recording_engine.accessibility.CallRecordingAccessibilityService
import com.pypecrm.call_recording_engine.data.EngineStats
import com.pypecrm.call_recording_engine.data.MediaProjectionTokenStore
import com.pypecrm.call_recording_engine.data.NativeAuthPrefs
import com.pypecrm.call_recording_engine.data.PhoneAccountPrefs
import com.pypecrm.call_recording_engine.debug.EngineDebugLog
import com.pypecrm.call_recording_engine.dialer.TelecomDialerManager
import com.pypecrm.call_recording_engine.service.CallMonitorService
import com.pypecrm.call_recording_engine.sync.CallSyncWorker
import com.pypecrm.call_recording_engine.sync.WhatsAppSyncWorker
import com.pypecrm.call_recording_engine.util.AccessibilityUtils
import com.pypecrm.call_recording_engine.util.AutoStartHelper
import com.pypecrm.call_recording_engine.util.NotificationListenerUtils
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

/**
 * Dart<->native bridge for every tier. All the actual call-monitoring logic
 * lives in CallStateReceiver/CallMonitorService/ProjectionCaptureService/
 * CallSyncWorker and keeps running whether or not Flutter's engine is
 * alive — this plugin only toggles that machinery on/off, requests runtime
 * permissions/consent, and reports status back to Dart when the UI is
 * open. See Dad-mobile/CALL_RECORDING_PLAN.md for the full architecture
 * this implements.
 *
 * Runtime permissions are requested here natively (ActivityCompat), not via
 * a generic permission-request pub package — READ_CALL_LOG in particular
 * belongs to Android's own "CALL_LOG" permission group, separate from the
 * "phone" group that covers READ_PHONE_STATE, and getting that distinction
 * wrong would silently break Tier 0/4 (both depend on reading the
 * CallLog). Owning the exact permission strings ourselves removes that risk.
 */
class CallRecordingEnginePlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    RequestPermissionsResultListener,
    ActivityResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private var activity: Activity? = null
    private var pendingPermissionResult: Result? = null
    private var pendingProjectionResult: Result? = null
    private var pendingDefaultDialerResult: Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.pypecrm.recorder/engine")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkPermissions" -> result.success(checkPermissions())
            "requestPermissions" -> requestPermissions(result)
            "startMonitoring" -> {
                EngineStats(appContext).monitoringEnabled = true
                startService(CallMonitorService.ACTION_ENSURE_RUNNING)
                CallSyncWorker.schedulePeriodic(appContext)
                // Notification access (if already granted) works independently
                // of the accessibility/foreground-service permission set this
                // action gates, but scheduling its periodic safety-net sync
                // here too costs nothing when the listener is never enabled —
                // WhatsAppSyncWorker just finds an empty queue and no-ops.
                WhatsAppSyncWorker.schedulePeriodic(appContext)
                result.success(null)
            }
            "stopMonitoring" -> {
                EngineStats(appContext).monitoringEnabled = false
                startService(CallMonitorService.ACTION_STOP)
                result.success(null)
            }
            "getStatus" -> {
                val stats = EngineStats(appContext)
                result.success(
                    mapOf(
                        "monitoringEnabled" to stats.monitoringEnabled,
                        "lastSyncedAtMillis" to stats.lastSyncedAtMillis,
                        "tier0SuccessCount" to stats.tier0SuccessCount,
                        "tier1SuccessCount" to stats.tier1SuccessCount,
                        "tier2SuccessCount" to stats.tier2SuccessCount,
                        "tier3SuccessCount" to stats.tier3SuccessCount,
                        "tier4SuccessCount" to stats.tier4SuccessCount,
                        "whatsAppSyncCount" to stats.whatsAppSyncCount,
                        "lastWhatsAppSyncedAtMillis" to stats.lastWhatsAppSyncAtMillis,
                    )
                )
            }
            "saveAuthForNative" -> {
                val token = call.argument<String>("token")
                val apiBaseUrl = call.argument<String>("apiBaseUrl")
                if (token.isNullOrEmpty() || apiBaseUrl.isNullOrEmpty()) {
                    result.error("bad_args", "token and apiBaseUrl are required", null)
                    return
                }
                NativeAuthPrefs(appContext).save(token, apiBaseUrl)
                result.success(null)
            }
            "clearAuthForNative" -> {
                NativeAuthPrefs(appContext).clear()
                // Also clear the PhoneAccount registration flag so a fresh
                // login always re-registers (avoids stale handles across
                // org/user switches).
                PhoneAccountPrefs(appContext).clear()
                result.success(null)
            }
            "isIgnoringBatteryOptimizations" ->
                result.success(AutoStartHelper.isIgnoringBatteryOptimizations(appContext))
            "requestBatteryOptimizationExemption" ->
                result.success(AutoStartHelper.requestIgnoreBatteryOptimizations(appContext))
            "openAutoStartSettings" ->
                result.success(AutoStartHelper.openAutoStartSettings(appContext))
            "getManufacturer" -> result.success(android.os.Build.MANUFACTURER)
            "isAccessibilityServiceEnabled" ->
                result.success(AccessibilityUtils.isCallRecordingServiceEnabled(appContext))
            "openAccessibilitySettings" -> result.success(openAccessibilitySettings())
            "isWhatsAppListenerEnabled" ->
                result.success(NotificationListenerUtils.isWhatsAppListenerEnabled(appContext))
            "openNotificationListenerSettings" -> result.success(openNotificationListenerSettings())
            "hasMediaProjectionToken" -> result.success(MediaProjectionTokenStore.hasToken())
            "requestMediaProjectionPermission" -> requestMediaProjectionPermission(result)
            "attemptEnableNativeCallRecording" -> attemptEnableNativeCallRecording(result)
            "syncCallLogsNow" -> {
                // User-visible manual trigger for the same reconcile-then-upload
                // pass CallSyncWorker already runs on its own (periodic tick, or
                // right after a call ends) — added because that automatic path
                // is invisible: it reuses the READ_CALL_LOG grant from onboarding
                // rather than asking for anything new, so there was previously no
                // UI moment that showed the feature exists or is working.
                CallSyncWorker.scheduleNow(appContext)
                result.success(null)
            }
            "getEngineDebugLog" -> result.success(EngineDebugLog(appContext).readAll())
            "clearEngineDebugLog" -> {
                EngineDebugLog(appContext).clear()
                result.success(null)
            }
            // ── Dialer / Telecom ──────────────────────────────────────────────
            "registerPhoneAccount" ->
                result.success(TelecomDialerManager.registerPhoneAccount(appContext))
            "isDefaultDialer" ->
                result.success(TelecomDialerManager.isDefaultDialer(appContext))
            "requestDefaultDialerRole" -> {
                val currentActivity = activity
                if (currentActivity == null) {
                    result.error("no_activity", "No Activity attached to request default-dialer role", null)
                    return
                }
                pendingDefaultDialerResult = result
                TelecomDialerManager.requestDefaultDialerRole(currentActivity)
                // Result delivered via onActivityResult -> pendingDefaultDialerResult
            }
            "placeCall" -> {
                val number = call.argument<String>("number")
                if (number.isNullOrBlank()) {
                    result.error("bad_args", "number is required", null)
                    return
                }
                TelecomDialerManager.placeCall(appContext, number)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** The dangerous/runtime subset of the full permission set declared in
     * the host app's manifest (see
     * Dad-call-recorder/android/app/src/main/AndroidManifest.xml) —
     * MODIFY_AUDIO_SETTINGS and the FOREGROUND_SERVICE_* subtypes are
     * normal permissions granted at install time, so they don't belong
     * here, and neither does Tier 2's Accessibility Service or Tier 3's
     * MediaProjection consent — both are granted through their own OS
     * flows (system Settings, and a one-time consent dialog respectively),
     * not the standard runtime-permission dialog. READ_MEDIA_AUDIO
     * replaces READ_EXTERNAL_STORAGE on 33+, and POST_NOTIFICATIONS is
     * only a runtime permission from 33+. */
    private fun requiredPermissions(): Array<String> {
        val permissions = mutableListOf(
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.READ_CALL_LOG,
            Manifest.permission.RECORD_AUDIO,
            // Dialer role: CALL_PHONE to place calls, ANSWER_PHONE_CALLS to
            // answer via PypeConnection. MANAGE_OWN_CALLS is a normal
            // permission (granted at install) so it's not listed here.
            // READ_CONTACTS for CRM lead-name matching while dialing.
            // Manifest must always match this list — see the class-level doc
            // comment on CallRecordingEnginePlugin for why we own these
            // explicitly rather than delegating to a generic plugin.
            Manifest.permission.CALL_PHONE,
            Manifest.permission.ANSWER_PHONE_CALLS,
            Manifest.permission.READ_CONTACTS,
        )
        permissions += if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions += Manifest.permission.POST_NOTIFICATIONS
        }
        return permissions.toTypedArray()
    }

    private fun checkPermissions(): Map<String, Boolean> =
        requiredPermissions().associateWith {
            ContextCompat.checkSelfPermission(appContext, it) == PackageManager.PERMISSION_GRANTED
        }

    private fun requestPermissions(result: Result) {
        val currentActivity = activity
        val missing = requiredPermissions().filter {
            ContextCompat.checkSelfPermission(appContext, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            result.success(checkPermissions())
            return
        }
        if (currentActivity == null) {
            result.error("no_activity", "No Activity attached to request permissions from", null)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(currentActivity, missing.toTypedArray(), PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        pendingPermissionResult?.success(checkPermissions())
        pendingPermissionResult = null
        return true
    }

    /** Opens system Settings > Accessibility so the user can enable
     * CallRecordingAccessibilityService by hand — Android does not allow
     * an app to enable its own accessibility service programmatically. */
    private fun openAccessibilitySettings(): Boolean {
        val currentActivity = activity ?: return try {
            appContext.startActivity(
                Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            true
        } catch (e: Exception) {
            false
        }
        return try {
            currentActivity.startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
            true
        } catch (e: Exception) {
            false
        }
    }

    /** Opens system Settings > Notification access, same one-way pattern as
     * [openAccessibilitySettings] — Android does not allow an app to enable
     * itself as a notification listener. */
    private fun openNotificationListenerSettings(): Boolean {
        val currentActivity = activity ?: return try {
            appContext.startActivity(
                Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            true
        } catch (e: Exception) {
            false
        }
        return try {
            currentActivity.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
            true
        } catch (e: Exception) {
            false
        }
    }

    /** Launches the system's MediaProjection consent dialog. The result
     * (captured in [onActivityResult]) is stored in
     * [MediaProjectionTokenStore] for CallMonitorService/ProjectionCaptureService
     * to use — this can only be requested from a foreground Activity, and
     * only lasts for this process's lifetime (see the token store's doc
     * comment on why). */
    private fun requestMediaProjectionPermission(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("no_activity", "No Activity attached to request MediaProjection from", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(false)
            return
        }
        pendingProjectionResult = result
        val manager =
            currentActivity.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        currentActivity.startActivityForResult(manager.createScreenCaptureIntent(), PROJECTION_REQUEST_CODE)
    }

    /** Fire-and-forget — the automation runs for several seconds across
     * multiple screen transitions, so its result is read back from
     * [EngineDebugLog] (via getEngineDebugLog), not this call's return
     * value. Requires the user to have already enabled the accessibility
     * service (same prerequisite as Tier 2). */
    private fun attemptEnableNativeCallRecording(result: Result) {
        val service = CallRecordingAccessibilityService.instance
        if (service == null) {
            result.error("service_not_enabled", "Accessibility service is not currently enabled", null)
            return
        }
        service.attemptSamsungAutoRecordSetup()
        result.success(null)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        when (requestCode) {
            PROJECTION_REQUEST_CODE -> {
                MediaProjectionTokenStore.store(resultCode, data)
                pendingProjectionResult?.success(MediaProjectionTokenStore.hasToken())
                pendingProjectionResult = null
                return true
            }
            TelecomDialerManager.REQUEST_CODE_SET_DEFAULT_DIALER -> {
                val isNowDefault = TelecomDialerManager.isDefaultDialer(appContext)
                if (isNowDefault) {
                    EngineDebugLog(appContext).append(
                        "DIALER_SET_AS_DEFAULT",
                        "User granted default-dialer role to PypeCRM Helper"
                    )
                } else {
                    EngineDebugLog(appContext).append(
                        "DIALER_UNSET_AS_DEFAULT",
                        "User did not grant default-dialer role (or revoked it)",
                        level = "warn"
                    )
                }
                pendingDefaultDialerResult?.success(isNowDefault)
                pendingDefaultDialerResult = null
                return true
            }
        }
        return false
    }

    /** Always startForegroundService — even for [CallMonitorService.ACTION_STOP]
     * — since Android 8+ restricts plain startService() from a background
     * app context, and the service itself is safe to receive a stop action
     * as its very first (cold) start. */
    private fun startService(action: String) {
        appContext.startForegroundService(
            Intent(appContext, CallMonitorService::class.java).apply { this.action = action }
        )
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
        binding.addActivityResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    companion object {
        private const val PERMISSION_REQUEST_CODE = 4202
        private const val PROJECTION_REQUEST_CODE = 4203
        // 4204 is TelecomDialerManager.REQUEST_CODE_SET_DEFAULT_DIALER
    }
}
