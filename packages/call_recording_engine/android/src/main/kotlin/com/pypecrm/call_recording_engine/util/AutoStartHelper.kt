package com.pypecrm.call_recording_engine.util

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

/**
 * Adapted from Dad-frontend's AutoStartHelper.kt — same manufacturer-keyed
 * table of OEM auto-start/security-center screens, since it's already a
 * solid reference for these deep links. Two changes: it no longer shows its
 * own AlertDialog (the Dart onboarding screen owns that explanation now —
 * this is purely the "perform the navigation" half), and every
 * `startActivity` call carries `FLAG_ACTIVITY_NEW_TASK` since this always
 * runs from application context, not an Activity.
 */
object AutoStartHelper {

    private const val TAG = "AutoStartHelper"

    fun openAutoStartSettings(context: Context): Boolean {
        val target = when (Build.MANUFACTURER.lowercase()) {
            "xiaomi", "redmi", "poco" -> componentIfInstalled(
                context, "com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"
            )
            "letv" -> componentIfInstalled(
                context, "com.letv.android.letvsafe", "com.letv.android.letvsafe.AutobootManageActivity"
            )
            "honor", "huawei" -> componentIfInstalled(
                context, "com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"
            )
            "oppo" -> componentIfInstalled(
                context, "com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"
            ) ?: componentIfInstalled(
                context, "com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"
            )
            "vivo" -> componentIfInstalled(
                context, "com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity"
            ) ?: componentIfInstalled(
                context, "com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
            )
            "nokia" -> componentIfInstalled(
                context, "com.evenwell.powersaving.g3", "com.evenwell.powersaving.g3.exception.PowerSaverExceptionActivity"
            )
            "asus" -> componentIfInstalled(
                context, "com.asus.mobilemanager", "com.asus.mobilemanager.entry.FunctionActivity"
            )
            else -> null
        }

        if (target != null) {
            val started = tryStart(
                context,
                Intent().apply {
                    component = target
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
            if (started) return true
        }
        return requestIgnoreBatteryOptimizations(context)
    }

    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    fun requestIgnoreBatteryOptimizations(context: Context): Boolean {
        if (isIgnoringBatteryOptimizations(context)) return true
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:${context.packageName}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return tryStart(context, intent)
    }

    private fun tryStart(context: Context, intent: Intent): Boolean = try {
        context.startActivity(intent)
        true
    } catch (e: Exception) {
        Log.e(TAG, "Failed to start settings intent: $intent", e)
        false
    }

    private fun componentIfInstalled(context: Context, packageName: String, className: String): ComponentName? =
        if (isPackageInstalled(context, packageName)) ComponentName(packageName, className) else null

    private fun isPackageInstalled(context: Context, packageName: String): Boolean = try {
        context.packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }
}
