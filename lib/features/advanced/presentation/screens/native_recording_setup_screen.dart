import 'dart:async';

import 'package:call_recording_engine/call_recording_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../status/providers/engine_provider.dart';

/// Advanced/experimental. Triggers [CallRecordingEngine.attemptEnableNativeCallRecording]
/// (currently: Samsung One UI's stock dialer auto-record toggle) and shows
/// the live event log while it runs — this is unverified against real
/// Samsung hardware, so the log is the actual verification surface: if a
/// step fails, what it saw on screen is right there to read and report
/// back, the same real-device iterate loop already used elsewhere in this
/// project (see e.g. the CallLog-matching fix).
class NativeRecordingSetupScreen extends ConsumerStatefulWidget {
  const NativeRecordingSetupScreen({super.key});

  @override
  ConsumerState<NativeRecordingSetupScreen> createState() => _NativeRecordingSetupScreenState();
}

class _NativeRecordingSetupScreenState extends ConsumerState<NativeRecordingSetupScreen> {
  Timer? _timer;
  List<Map<String, Object?>> _log = const [];
  bool _running = false;
  String? _error;

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
    final log = await _engine.getEngineDebugLog();
    if (!mounted) return;
    setState(() => _log = log);
  }

  Future<void> _start() async {
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      await _engine.clearEngineDebugLog();
      await _engine.attemptEnableNativeCallRecording();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _running = false);
    }
    await _poll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-enable native recording'),
        actions: [
          IconButton(
            tooltip: 'Clear log',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await _engine.clearEngineDebugLog();
              await _poll();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Experimental, Samsung One UI only for now. Opens the phone\'s own '
            'dialer and tries to switch on its built-in call-recording setting, '
            'so the phone itself records calls (Tier 0 then just has to find the '
            'file) instead of this app trying to capture audio directly. Requires '
            'the accessibility service to already be enabled.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: _running
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: Text(_running ? 'Running…' : 'Try to enable now'),
            onPressed: _running ? null : _start,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          Text('Event log', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_log.isEmpty) const Text('No events yet — tap "Try to enable now" above.'),
          ..._log.map((e) => _LogLine(entry: e)),
        ],
      ),
    );
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
    final event = entry['event'] as String? ?? '';
    final isFailure = event.contains('FAILED') || event.contains('STOPPED');
    final isSuccess = event.contains('SUCCESS');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        '$ts  $event  ${entry['detail']}',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: isFailure ? Colors.red : (isSuccess ? Colors.green : null),
        ),
      ),
    );
  }
}
