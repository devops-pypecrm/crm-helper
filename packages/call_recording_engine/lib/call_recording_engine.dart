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
  /// enable "PypeCRM Helper" by hand — there's no way to deep-link
  /// straight to a specific service's toggle.
  Future<bool> openAccessibilitySettings() async =>
      (await _channel.invokeMethod<bool>('openAccessibilitySettings')) ?? false;

  /// Whether the user has granted this app "Notification access" in system
  /// Settings — required for [WhatsAppSyncListenerService] (native side) to
  /// read WhatsApp notification content at all. Android doesn't let an app
  /// grant this to itself — see [openNotificationListenerSettings] for the
  /// action half.
  Future<bool> isWhatsAppListenerEnabled() async =>
      (await _channel.invokeMethod<bool>('isWhatsAppListenerEnabled')) ?? false;

  /// Opens system Settings > Notification access. The user still has to
  /// find and enable this app by hand — same limitation as
  /// [openAccessibilitySettings].
  Future<bool> openNotificationListenerSettings() async =>
      (await _channel.invokeMethod<bool>('openNotificationListenerSettings')) ?? false;

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

  /// Advanced/experimental: triggers a best-effort UI automation (via the
  /// already-enabled accessibility service) that opens the phone's stock
  /// dialer and tries to switch on its built-in auto-call-recording
  /// setting — currently targets Samsung One UI only. Fire-and-forget; read
  /// progress/outcome back from [getEngineDebugLog], not this call's return
  /// value. Throws a PlatformException with code `service_not_enabled` if
  /// the accessibility service isn't currently enabled.
  Future<void> attemptEnableNativeCallRecording() =>
      _channel.invokeMethod('attemptEnableNativeCallRecording');

  /// Newest-first `{event, detail, timestampMillis}` list covering both
  /// Tier 0 (native-recording scan) and the auto-enable automation above —
  /// see `EngineDebugLog`'s doc comment on why this exists instead of
  /// relying on logcat (several OEMs suppress third-party app logs there).
  Future<List<Map<String, Object?>>> getEngineDebugLog() async {
    final raw = await _channel.invokeListMethod<Object?>('getEngineDebugLog');
    return (raw ?? const []).cast<Map<Object?, Object?>>().map((e) => e.cast<String, Object?>()).toList();
  }

  Future<void> clearEngineDebugLog() => _channel.invokeMethod('clearEngineDebugLog');

  /// Manually triggers the same reconcile-then-upload pass CallSyncWorker
  /// already runs on its own (see CallLogReconciler) — this scans the
  /// system CallLog for anything since the last watermark and queues it,
  /// then flushes the upload queue. Runs inline (bypassing the client-side
  /// bulk-sync cooldown) and doesn't resolve until the pass has actually
  /// finished — the returned [ManualSyncResult] reflects what really
  /// happened, not just that the work was scheduled.
  Future<ManualSyncResult> syncCallLogsNow() async {
    final raw = await _channel.invokeMapMethod<String, Object?>('syncCallLogsNow');
    return ManualSyncResult.fromMap(raw ?? const {});
  }

  /// Rewinds the native reconcile watermark to local midnight, then runs
  /// the same reconcile-then-upload pass [syncCallLogsNow] does — so this
  /// re-reads EVERY call from today (already-synced or not) instead of
  /// only new ones, and re-sends them. The backend heals (corrects) an
  /// already-known call rather than duplicating it. Slower than a plain
  /// sync and meant to be an explicit, occasional user action ("Re-check
  /// Today's Calls"), not something run on every regular sync. Same
  /// inline/awaited behavior as [syncCallLogsNow] — see its doc comment.
  Future<ManualSyncResult> reverifyToday() async {
    final raw = await _channel.invokeMapMethod<String, Object?>('reverifyToday');
    return ManualSyncResult.fromMap(raw ?? const {});
  }

  /// Convenience constant for reading the READ_CALL_LOG entry out of
  /// [checkPermissions]'s result map.
  static const readCallLogPermission = 'android.permission.READ_CALL_LOG';
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
    required this.whatsAppSyncCount,
    required this.lastWhatsAppSyncedAt,
  });

  factory EngineStatus.fromMap(Map<String, Object?> map) {
    final lastSyncedAtMillis = (map['lastSyncedAtMillis'] as num?)?.toInt() ?? 0;
    final lastWhatsAppSyncedAtMillis = (map['lastWhatsAppSyncedAtMillis'] as num?)?.toInt() ?? 0;
    return EngineStatus(
      monitoringEnabled: map['monitoringEnabled'] as bool? ?? false,
      lastSyncedAt:
          lastSyncedAtMillis > 0 ? DateTime.fromMillisecondsSinceEpoch(lastSyncedAtMillis) : null,
      tier0SuccessCount: (map['tier0SuccessCount'] as num?)?.toInt() ?? 0,
      tier1SuccessCount: (map['tier1SuccessCount'] as num?)?.toInt() ?? 0,
      tier2SuccessCount: (map['tier2SuccessCount'] as num?)?.toInt() ?? 0,
      tier3SuccessCount: (map['tier3SuccessCount'] as num?)?.toInt() ?? 0,
      tier4SuccessCount: (map['tier4SuccessCount'] as num?)?.toInt() ?? 0,
      whatsAppSyncCount: (map['whatsAppSyncCount'] as num?)?.toInt() ?? 0,
      lastWhatsAppSyncedAt: lastWhatsAppSyncedAtMillis > 0
          ? DateTime.fromMillisecondsSinceEpoch(lastWhatsAppSyncedAtMillis)
          : null,
    );
  }

  final bool monitoringEnabled;
  final DateTime? lastSyncedAt;
  final int tier0SuccessCount;
  final int tier1SuccessCount;
  final int tier2SuccessCount;
  final int tier3SuccessCount;
  final int tier4SuccessCount;
  final int whatsAppSyncCount;
  final DateTime? lastWhatsAppSyncedAt;

  int get totalSyncedCalls =>
      tier0SuccessCount + tier1SuccessCount + tier2SuccessCount + tier3SuccessCount + tier4SuccessCount;
}

enum ManualSyncStatus { success, rateLimited, failed, permissionMissing, notSignedIn }

/// Real outcome of [CallRecordingEngine.syncCallLogsNow] /
/// [CallRecordingEngine.reverifyToday] — both now run inline and don't
/// resolve until the native side has actually finished, so this reflects
/// what happened rather than just that the work was scheduled.
class ManualSyncResult {
  const ManualSyncResult({
    required this.status,
    this.reconciledCount = 0,
    this.syncedCount = 0,
    this.pendingCount = 0,
    this.retryAfterSeconds,
    this.httpCode,
  });

  factory ManualSyncResult.fromMap(Map<String, Object?> map) {
    final status = switch (map['status'] as String?) {
      'success' => ManualSyncStatus.success,
      'rateLimited' => ManualSyncStatus.rateLimited,
      'permissionMissing' => ManualSyncStatus.permissionMissing,
      'notSignedIn' => ManualSyncStatus.notSignedIn,
      _ => ManualSyncStatus.failed,
    };
    return ManualSyncResult(
      status: status,
      reconciledCount: (map['reconciledCount'] as num?)?.toInt() ?? 0,
      syncedCount: (map['syncedCount'] as num?)?.toInt() ?? 0,
      pendingCount: (map['pendingCount'] as num?)?.toInt() ?? 0,
      retryAfterSeconds: (map['retryAfterSeconds'] as num?)?.toInt(),
      httpCode: (map['httpCode'] as num?)?.toInt(),
    );
  }

  final ManualSyncStatus status;
  final int reconciledCount;
  final int syncedCount;
  final int pendingCount;
  final int? retryAfterSeconds;

  /// Only set when [status] is [ManualSyncStatus.failed] and the failure was
  /// an HTTP response (null means a network-level failure — timeout, no
  /// connection). 401/403 means the stored session is dead and nothing will
  /// change until the user re-authenticates; anything else is more likely
  /// transient (server error) and will probably heal on its own retry.
  final int? httpCode;
}
