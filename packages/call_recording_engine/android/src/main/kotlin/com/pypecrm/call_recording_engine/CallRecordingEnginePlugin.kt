package com.pypecrm.call_recording_engine

import android.Manifest
import android.app.Activity
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.telecom.TelecomManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.pypecrm.call_recording_engine.data.EngineStats
import com.pypecrm.call_recording_engine.data.MediaProjectionTokenStore
import com.pypecrm.call_recording_engine.data.NativeAuthPrefs
import com.pypecrm.call_recording_engine.service.CallMonitorService
import com.pypecrm.call_recording_engine.sync.CallSyncWorker
import com.pypecrm.call_recording_engine.telecom.CallDebugLog
import com.pypecrm.call_recording_engine.telecom.CallStateMachine
import com.pypecrm.call_recording_engine.telecom.PocConfig
import com.pypecrm.call_recording_engine.util.AccessibilityUtils
import com.pypecrm.call_recording_engine.util.AutoStartHelper
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
    private var pendingDialerRoleResult: Result? = null

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
            "hasMediaProjectionToken" -> result.success(MediaProjectionTokenStore.hasToken())
            "requestMediaProjectionPermission" -> requestMediaProjectionPermission(result)
            "isDefaultDialer" -> result.success(isDefaultDialer())
            "requestDialerRole" -> requestDialerRole(result)
            "setPocRole" -> {
                PocConfig(appContext).role = call.argument<String>("role")
                result.success(null)
            }
            "getPocRole" -> result.success(PocConfig(appContext).role)
            "setRecordingNumber" -> {
                PocConfig(appContext).recordingNumber = call.argument<String>("number")
                result.success(null)
            }
            "getDebugLog" -> result.success(CallDebugLog(appContext).readAll())
            "getCallDebugState" -> result.success(CallStateMachine(appContext).snapshot())
            "clearDebugLog" -> {
                CallDebugLog(appContext).clear()
                CallStateMachine(appContext).reset()
                result.success(null)
            }
            "startPocDialerCall" -> startPocDialerCall(call.argument<String>("number"), result)
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        when (requestCode) {
            PROJECTION_REQUEST_CODE -> {
                MediaProjectionTokenStore.store(resultCode, data)
                pendingProjectionResult?.success(MediaProjectionTokenStore.hasToken())
                pendingProjectionResult = null
                return true
            }
            DIALER_ROLE_REQUEST_CODE -> {
                pendingDialerRoleResult?.success(isDefaultDialer())
                pendingDialerRoleResult = null
                return true
            }
        }
        return false
    }

    /** Milestone 1 POC only. Whether this app currently holds
     * `RoleManager.ROLE_DIALER` — required before `InCallService`
     * callbacks or `TelecomManager.placeCall()` do anything useful. */
    private fun isDefaultDialer(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val roleManager = appContext.getSystemService(Context.ROLE_SERVICE) as? RoleManager ?: return false
        return roleManager.isRoleHeld(RoleManager.ROLE_DIALER)
    }

    /** Launches the system's "set as default dialer" confirmation dialog.
     * Both POC roles (Dialer AND Recorder) need this — the Recorder phone
     * also needs `ROLE_DIALER` to auto-answer via `Call.answer()` and be
     * bound as the `InCallService` for its incoming leg (see
     * PypeInCallService's doc comment). */
    private fun requestDialerRole(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("no_activity", "No Activity attached to request the dialer role from", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(false)
            return
        }
        if (isDefaultDialer()) {
            result.success(true)
            return
        }
        val roleManager = currentActivity.getSystemService(Context.ROLE_SERVICE) as RoleManager
        pendingDialerRoleResult = result
        currentActivity.startActivityForResult(
            roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER),
            DIALER_ROLE_REQUEST_CODE,
        )
    }

    /** Milestone 1 POC only. Places the initial customer-facing call —
     * everything downstream (recorder-leg call, conference attempt) is
     * driven by `PypeInCallService`/`ConferenceOrchestrator` reacting to
     * this call reaching `STATE_ACTIVE`, not by this method directly. */
    private fun startPocDialerCall(number: String?, result: Result) {
        if (number.isNullOrBlank()) {
            result.error("bad_args", "number is required", null)
            return
        }
        if (!isDefaultDialer()) {
            result.error("not_dialer_role", "This app does not hold ROLE_DIALER", null)
            return
        }
        val telecomManager = appContext.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        try {
            telecomManager.placeCall(Uri.fromParts("tel", number, null), null)
            result.success(null)
        } catch (e: Exception) {
            result.error("place_call_failed", e.message ?: e.toString(), null)
        }
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
        private const val DIALER_ROLE_REQUEST_CODE = 4204
    }
}
