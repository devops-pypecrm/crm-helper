import 'package:flutter/services.dart';

/// Dart-side handle to the native call-monitoring engine implemented in
/// `android/src/main/kotlin/com/pypecrm/call_recording_engine/` (Kotlin —
/// BroadcastReceiver + foreground Service + WorkManager, all independent of
/// this Dart isolate's lifecycle; see Dad-mobile/CALL_RECORDING_PLAN.md).
///
/// This is a plain [MethodChannel] wrapper, not the usual federated
/// platform-interface/method-channel split pub.dev plugins use — this
/// plugin is private, Android-only, and will never grow another platform
/// implementation, so that indirection would be pure ceremony.
class CallRecordingEngine {
  CallRecordingEngine({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.pypecrm.recorder/engine');

  final MethodChannel _channel;

  /// The exact Phase 1 runtime-permission set (READ_PHONE_STATE,
  /// READ_CALL_LOG, READ_MEDIA_AUDIO/READ_EXTERNAL_STORAGE, and — on 33+ —
  /// POST_NOTIFICATIONS), each mapped to whether it's currently granted.
  Future<Map<String, bool>> checkPermissions() async {
    final raw = await _channel.invokeMapMethod<String, Object?>('checkPermissions');
    return (raw ?? const {}).map((key, value) => MapEntry(key, value as bool? ?? false));
  }

  /// Requests every not-yet-granted permission from [checkPermissions] in
  /// one system dialog batch, and returns the resulting grant map. Requires
  /// a foreground Activity — call this from the onboarding screen, not a
  /// background isolate.
  Future<Map<String, bool>> requestPermissions() async {
    final raw = await _channel.invokeMapMethod<String, Object?>('requestPermissions');
    return (raw ?? const {}).map((key, value) => MapEntry(key, value as bool? ?? false));
  }

  /// Enables monitoring: persists the flag natively and starts the
  /// always-on foreground service that watches for calls. Call only after
  /// the required permissions are granted and the user is signed in
  /// (native auth must already be saved via [saveAuthForNative]).
  Future<void> startMonitoring() => _channel.invokeMethod('startMonitoring');

  /// Disables monitoring and stops the foreground service. Safe to call any
  /// time, including when monitoring was never started.
  Future<void> stopMonitoring() => _channel.invokeMethod('stopMonitoring');

  Future<EngineStatus> getStatus() async {
    final raw = await _channel.invokeMapMethod<String, Object?>('getStatus');
    return EngineStatus.fromMap(raw ?? const {});
  }

  /// Duplicates the JWT + API base URL into native-side storage so the
  /// foreground service / WorkManager can authenticate on their own even
  /// when the Flutter engine is fully suspended. Call right after a
  /// successful login (and again after any future token refresh).
  Future<void> saveAuthForNative({required String token, required String apiBaseUrl}) =>
      _channel.invokeMethod('saveAuthForNative', {'token': token, 'apiBaseUrl': apiBaseUrl});

  /// Call on logout — otherwise the background service would keep
  /// uploading calls under the previous user's identity.
  Future<void> clearAuthForNative() => _channel.invokeMethod('clearAuthForNative');

  Future<bool> isIgnoringBatteryOptimizations() async =>
      (await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations')) ?? false;

  /// Opens the system's battery-optimization-exemption prompt for this app.
  /// Returns false only if the settings screen itself couldn't be launched
  /// — the user may still deny the request itself, which isn't observable
  /// from here; re-check with [isIgnoringBatteryOptimizations] after the
  /// user returns to the app.
  Future<bool> requestBatteryOptimizationExemption() async =>
      (await _channel.invokeMethod<bool>('requestBatteryOptimizationExemption')) ?? false;

  /// Opens the manufacturer-specific auto-start/background-activity screen
  /// (Xiaomi/Oppo/Vivo/Honor/Nokia/Asus) if one is detected, else falls
  /// back to the generic battery-optimization prompt.
  Future<bool> openAutoStartSettings() async =>
      (await _channel.invokeMethod<bool>('openAutoStartSettings')) ?? false;

  Future<String> getManufacturer() async =>
      (await _channel.invokeMethod<String>('getManufacturer')) ?? 'unknown';

  /// Tier 2: whether the user has enabled the call-recording Accessibility
  /// Service in system Settings. Android doesn't let an app enable its own
  /// accessibility service, so this is check-only — see
  /// [openAccessibilitySettings] for the action half.
  Future<bool> isAccessibilityServiceEnabled() async =>
      (await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled')) ?? false;

  /// Opens system Settings > Accessibility. The user still has to find and
  /// enable "Pype Call Recorder" by hand — there's no way to deep-link
  /// straight to a specific service's toggle.
  Future<bool> openAccessibilitySettings() async =>
      (await _channel.invokeMethod<bool>('openAccessibilitySettings')) ?? false;

  /// Tier 3: whether a MediaProjection consent token is currently held.
  /// This is lost whenever the app process dies — check it fresh each time
  /// the status/onboarding screen opens rather than caching the result.
  Future<bool> hasMediaProjectionToken() async =>
      (await _channel.invokeMethod<bool>('hasMediaProjectionToken')) ?? false;

  /// Launches the system's MediaProjection consent dialog (a
  /// "this app can capture audio" style prompt) and returns whether a
  /// usable token resulted. Requires a foreground Activity, and does
  /// nothing below Android 10 (Tier 3 is API 29+ only).
  Future<bool> requestMediaProjectionPermission() async =>
      (await _channel.invokeMethod<bool>('requestMediaProjectionPermission')) ?? false;
}

class EngineStatus {
  const EngineStatus({
    required this.monitoringEnabled,
    required this.lastSyncedAt,
    required this.tier0SuccessCount,
    required this.tier1SuccessCount,
    required this.tier2SuccessCount,
    required this.tier3SuccessCount,
    required this.tier4SuccessCount,
  });

  factory EngineStatus.fromMap(Map<String, Object?> map) {
    final lastSyncedAtMillis = (map['lastSyncedAtMillis'] as num?)?.toInt() ?? 0;
    return EngineStatus(
      monitoringEnabled: map['monitoringEnabled'] as bool? ?? false,
      lastSyncedAt:
          lastSyncedAtMillis > 0 ? DateTime.fromMillisecondsSinceEpoch(lastSyncedAtMillis) : null,
      tier0SuccessCount: (map['tier0SuccessCount'] as num?)?.toInt() ?? 0,
      tier1SuccessCount: (map['tier1SuccessCount'] as num?)?.toInt() ?? 0,
      tier2SuccessCount: (map['tier2SuccessCount'] as num?)?.toInt() ?? 0,
      tier3SuccessCount: (map['tier3SuccessCount'] as num?)?.toInt() ?? 0,
      tier4SuccessCount: (map['tier4SuccessCount'] as num?)?.toInt() ?? 0,
    );
  }

  final bool monitoringEnabled;
  final DateTime? lastSyncedAt;
  final int tier0SuccessCount;
  final int tier1SuccessCount;
  final int tier2SuccessCount;
  final int tier3SuccessCount;
  final int tier4SuccessCount;

  int get totalSyncedCalls =>
      tier0SuccessCount + tier1SuccessCount + tier2SuccessCount + tier3SuccessCount + tier4SuccessCount;
}
