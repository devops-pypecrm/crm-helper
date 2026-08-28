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
}
