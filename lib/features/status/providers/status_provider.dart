import 'dart:async';

import 'package:call_recording_engine/call_recording_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'engine_provider.dart';

part 'status_provider.g.dart';

/// Polls the native engine's status every few seconds while the status
/// screen is open — there's no push channel from native to Dart in Phase 1
/// (the engine keeps running whether or not this screen is watching), so
/// polling is the simplest way to reflect what it's doing.
@riverpod
class EngineStatusController extends _$EngineStatusController {
  Timer? _timer;

  @override
  Future<EngineStatus> build() async {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
    return ref.read(callRecordingEngineProvider).getStatus();
  }

  Future<void> refresh() async {
    final status = await ref.read(callRecordingEngineProvider).getStatus();
    state = AsyncValue.data(status);
  }

  Future<void> toggleMonitoring(bool enabled) async {
    final engine = ref.read(callRecordingEngineProvider);
    if (enabled) {
      await engine.startMonitoring();
    } else {
      await engine.stopMonitoring();
    }
    await refresh();
  }

  /// Manual "sync now" for the periodic call-log reconciliation — see
  /// CallRecordingEngine.syncCallLogsNow's doc comment. That call now runs
  /// inline and doesn't resolve until the native side has actually
  /// finished, so the returned [ManualSyncResult] already reflects the
  /// real outcome — no more guessing from a before/after status poll.
  Future<ManualSyncResult> syncCallLogsNow() async {
    final result = await ref.read(callRecordingEngineProvider).syncCallLogsNow();
    await refresh();
    return result;
  }

  /// "Re-check Today's Calls" — see `CallRecordingEngine.reverifyToday`'s
  /// doc comment. Same shape as [syncCallLogsNow].
  Future<ManualSyncResult> reverifyToday() async {
    final result = await ref.read(callRecordingEngineProvider).reverifyToday();
    await refresh();
    return result;
  }
}

/// One-shot read of the Phase 1 runtime-permission grants, used to show a
/// plain "Call log history access: Granted" line on the Status screen —
/// this permission is requested as part of the same onboarding "Required
/// permissions" bundle as everything else, so there's no separate grant
/// step for it, but its status wasn't visible anywhere outside onboarding.
@riverpod
Future<Map<String, bool>> enginePermissions(AutoDisposeFutureProviderRef<Map<String, bool>> ref) =>
    ref.read(callRecordingEngineProvider).checkPermissions();
