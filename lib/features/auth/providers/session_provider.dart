import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/secure_storage_provider.dart';
import '../../status/providers/engine_provider.dart';
import '../data/auth_repository.dart';
import '../domain/user_session.dart';

part 'session_provider.g.dart';

/// Single source of truth for "who is logged in" — the login screen, the
/// status screen, and the Dio interceptor's 401 handler all watch this.
/// Mirrors Dad-mobile/lib/features/auth/providers/session_provider.dart,
/// with one addition: login/logout also push/clear the JWT into the native
/// engine's own storage (see [_syncNativeAuth]) so CallMonitorService and
/// CallSyncWorker can authenticate on their own, independent of whether
/// this Dart isolate is even alive.
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  bool _wasForcedLogout = false;

  /// One-shot read — returns the flag and resets it, so the login screen's
  /// "your session expired" notice shows exactly once.
  bool consumeForcedLogoutFlag() {
    final was = _wasForcedLogout;
    _wasForcedLogout = false;
    return was;
  }

  @override
  Future<UserSession?> build() => _restoreSession();

  Future<UserSession?> _restoreSession() async {
    final storage = ref.read(secureStorageServiceProvider);
    final token = await storage.readToken();
    if (token == null) return null;

    try {
      final repository = ref.read(authRepositoryProvider);
      final me = await repository.fetchCurrentUser();
      final session = me.copyWith(token: token);
      await storage.saveUserInfo(jsonEncode(session.toJson()));
      await _syncNativeAuth(session);
      return session;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // The Dio interceptor already cleared storage and will call
        // forceLogout(); returning null here keeps this build in sync.
        return null;
      }
      // Offline or backend unreachable: fall back to the last known
      // session so a device that's mid-onboarding stays usable.
      final cached = await storage.readUserInfo();
      if (cached == null) return null;
      final session = UserSession.fromJson(jsonDecode(cached) as Map<String, dynamic>).copyWith(
        token: token,
      );
      await _syncNativeAuth(session);
      return session;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final session = await repository.login(email: email, password: password);

      final storage = ref.read(secureStorageServiceProvider);
      await storage.saveToken(session.token!);
      await storage.saveUserInfo(jsonEncode(session.toJson()));
      await _syncNativeAuth(session);

      return session;
    });
  }

  Future<void> logout() async {
    await ref.read(secureStorageServiceProvider).clear();
    await ref.read(callRecordingEngineProvider).clearAuthForNative();
    await ref.read(callRecordingEngineProvider).stopMonitoring();
    state = const AsyncValue.data(null);
  }

  /// Invoked by the Dio interceptor on a 401 — must never throw.
  Future<void> forceLogout() async {
    _wasForcedLogout = true;
    await ref.read(secureStorageServiceProvider).clear();
    await ref.read(callRecordingEngineProvider).clearAuthForNative();
    state = const AsyncValue.data(null);
  }

  Future<void> _syncNativeAuth(UserSession session) async {
    final token = session.token;
    if (token == null) return;
    await ref.read(callRecordingEngineProvider).saveAuthForNative(
          token: token,
          apiBaseUrl: AppConfig.instance.apiBaseUrl,
        );
  }
}
