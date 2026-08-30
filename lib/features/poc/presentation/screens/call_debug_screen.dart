import 'dart:async';

import 'package:call_recording_engine/call_recording_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../status/providers/engine_provider.dart';

/// Milestone 1 POC only. Polls `CallStateMachine`/`CallDebugLog` off the
/// native side every ~1s and renders exactly the checklist + summary-block
/// format specified in the approved plan — this, not logcat (suppressed by
/// this OEM for third-party apps), is the actual verification surface for
/// the real-hardware test.
class CallDebugScreen extends ConsumerStatefulWidget {
  const CallDebugScreen({super.key});

  @override
  ConsumerState<CallDebugScreen> createState() => _CallDebugScreenState();
}

class _CallDebugScreenState extends ConsumerState<CallDebugScreen> {
  Timer? _timer;
  Map<String, Object?> _state = const {};
  List<Map<String, Object?>> _log = const [];

  CallRecordingEngine get _engine => ref.read(callRecordingEngineProvider);

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final state = await _engine.getCallDebugState();
    final log = await _engine.getDebugLog();
    if (!mounted) return;
    setState(() {
      _state = state;
      _log = log;
    });
  }

  bool _b(String key) => _state[key] == true;
  int _i(String key) => (_state[key] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final callState = _state['state'] as String? ?? 'IDLE';
    final outcome = _state['outcome'] as String?;
    final callEnded = callState == 'CALL_ENDED' || outcome != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POC Debug Panel'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await _engine.clearDebugLog();
              await _poll();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('STATE: $callState', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildChecklist(),
            ),
          ),
          if (callEnded) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildSummary(outcome),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Pre-merge state dump', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._log
              .where((e) => (e['event'] as String? ?? '').contains('PRE_MERGE_STATE'))
              .map((e) => _LogLine(entry: e)),
          const SizedBox(height: 16),
          Text('Full event log', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._log.map((e) => _LogLine(entry: e)),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
    Widget row(String leftLabel, bool leftVal, String rightLabel, String rightVal) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text('$leftLabel  ${leftVal ? '✓' : '✗'}', style: const TextStyle(fontFamily: 'monospace'))),
            Expanded(child: Text('$rightLabel  $rightVal', style: const TextStyle(fontFamily: 'monospace'))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('CUSTOMER_CALL_STARTED', _b('customerCallStarted'), 'RECORDER_CALL_STARTED', _b('recorderCallStarted') ? '✓' : '✗'),
        row('CUSTOMER_CALL_ACTIVE', _b('customerCallActive'), 'RECORDER_CALL_ACTIVE', _b('recorderCallActive') ? '✓' : '✗'),
        row('CONFERENCE_CAPABILITY', _b('conferenceCapabilityPresent'), 'CONFERENCE_REQUESTED', _b('conferenceRequested') ? '✓' : '✗'),
        row('CONFERENCE_CREATED', _b('conferenceCreated'), 'THREE_WAY_CALL_ACTIVE', _b('threeWayCallActive') ? '✓' : '✗'),
        row('RECORDER_AUDIO_CREATED', _b('recorderAudioCreated'), 'RECORDER_DURATION', '${_i('recorderDurationSeconds')} sec'),
        if ((_state['recorderFilePath'] as String?)?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text('File: ${_state['recorderFilePath']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildSummary(String? outcome) {
    String ok(bool v) => v ? 'SUCCESS' : 'FAILED';
    final customerOk = _b('customerCallActive');
    final recorderCallOk = _b('recorderCallActive');
    final recorderAudioOk = _b('recorderAudioCreated') && _i('recorderDurationSeconds') > 0;
    final overallPass = outcome == 'FULL_SUCCESS';

    String outcomeMarker(String code) => outcome == code ? '>>>' : '   ';

    final buffer = StringBuffer()
      ..writeln('================================================')
      ..writeln('PYPE TRUECALLER-STYLE CONFERENCE POC')
      ..writeln('================================================')
      ..writeln('Customer call:             ${ok(customerOk)}')
      ..writeln('Recorder call:             ${ok(recorderCallOk)}')
      ..writeln('Recorder captured audio:   ${ok(recorderAudioOk)} (file present + duration > 0)')
      ..writeln()
      ..writeln('OUTCOME:  ${outcomeMarker('PROGRAMMATIC_CONFERENCE_API_UNAVAILABLE')}A — PROGRAMMATIC_CONFERENCE_API_UNAVAILABLE')
      ..writeln('          ${outcomeMarker('CONFERENCE_REJECTED')}B — CONFERENCE_REJECTED')
      ..writeln('          ${outcomeMarker('CONFERENCE_CREATED')}C — CONFERENCE_CREATED (no audio confirmed yet)')
      ..writeln('          ${outcomeMarker('CONFERENCE_NO_RECORDER_AUDIO')}D — CONFERENCE_NO_RECORDER_AUDIO')
      ..writeln('          ${outcomeMarker('FULL_SUCCESS')}E — FULL_SUCCESS')
      ..writeln('OVERALL:  [ ${overallPass ? 'PASS (E)' : 'FAIL (A/B/D)'} ]')
      ..write('================================================');

    return Text(buffer.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12));
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.entry});

  final Map<String, Object?> entry;

  @override
  Widget build(BuildContext context) {
    final millis = (entry['timestampMillis'] as num?)?.toInt() ?? 0;
    final time = millis > 0 ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
    final ts = time == null
        ? ''
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$ts  ${entry['event']}  ${entry['detail']}',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      ),
    );
  }
}
