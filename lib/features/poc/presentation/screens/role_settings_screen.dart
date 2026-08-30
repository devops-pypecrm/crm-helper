import 'package:call_recording_engine/call_recording_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../status/providers/engine_provider.dart';
import 'call_debug_screen.dart';

/// Milestone 1 POC only — configures which role this physical device plays
/// in the conference-recording experiment (Dialer or Recorder), requests
/// `RoleManager.ROLE_DIALER` (both roles need it — see
/// `PypeInCallService`'s doc comment), and is the entry point to
/// [CallDebugScreen]. Reached only via a hidden long-press on the status
/// screen's app-bar title — this is a debug surface, not shipped UI.
class RoleSettingsScreen extends ConsumerStatefulWidget {
  const RoleSettingsScreen({super.key});

  @override
  ConsumerState<RoleSettingsScreen> createState() => _RoleSettingsScreenState();
}

class _RoleSettingsScreenState extends ConsumerState<RoleSettingsScreen> {
  String? _role;
  bool _isDialerRoleHeld = false;
  bool _loading = true;
  final _recordingNumberController = TextEditingController();
  final _customerNumberController = TextEditingController();

  CallRecordingEngine get _engine => ref.read(callRecordingEngineProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _recordingNumberController.dispose();
    _customerNumberController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final role = await _engine.getPocRole();
    final isDialerRoleHeld = await _engine.isDefaultDialer();
    if (!mounted) return;
    setState(() {
      _role = role;
      _isDialerRoleHeld = isDialerRoleHeld;
      _loading = false;
    });
  }

  Future<void> _setRole(String? role) async {
    await _engine.setPocRole(role);
    setState(() => _role = role);
  }

  Future<void> _requestDialerRole() async {
    final held = await _engine.requestDialerRole();
    if (!mounted) return;
    setState(() => _isDialerRoleHeld = held);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('POC: Conference Recording (Milestone 1)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Milestone 1 only: proves whether a real carrier 3-way conference '
            'can be created programmatically. No backend calls, no upload — '
            'the recorder file stays on this device.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This device is:', style: Theme.of(context).textTheme.titleMedium),
                  RadioListTile<String?>(
                    title: const Text('Off (normal monitoring)'),
                    value: null,
                    groupValue: _role,
                    onChanged: (v) => _setRole(v),
                  ),
                  RadioListTile<String?>(
                    title: const Text('Dialer'),
                    subtitle: const Text('Places the customer call, then the recorder-leg call, then attempts the merge.'),
                    value: PocConfig.roleDialer,
                    groupValue: _role,
                    onChanged: (v) => _setRole(v),
                  ),
                  RadioListTile<String?>(
                    title: const Text('Recorder'),
                    subtitle: const Text('Auto-answers the recorder-leg call and captures audio locally.'),
                    value: PocConfig.roleRecorder,
                    groupValue: _role,
                    onChanged: (v) => _setRole(v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isDialerRoleHeld ? 'Default dialer: YES' : 'Default dialer: NO',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _isDialerRoleHeld ? Colors.green : Colors.red),
                      ),
                      if (!_isDialerRoleHeld)
                        FilledButton(onPressed: _requestDialerRole, child: const Text('Request role')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Both roles need this — required to bind PypeInCallService and, on the '
                    'Recorder role, to auto-answer via Call.answer().',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (_role == PocConfig.roleDialer) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dialer config', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _recordingNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Recorder SIM number'),
                      onChanged: (v) => _engine.setRecordingNumber(v.isEmpty ? null : v),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customerNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Customer number to call'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.call),
                      label: const Text('Start POC call'),
                      onPressed: !_isDialerRoleHeld
                          ? null
                          : () async {
                              await _engine.clearDebugLog();
                              await _engine.startPocDialerCall(_customerNumberController.text);
                              if (!mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CallDebugScreen()),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.bug_report_outlined),
            label: const Text('Open debug panel'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CallDebugScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mirrors the role strings `PocConfig.kt` uses natively — kept here rather
/// than importing anything from the plugin's Kotlin source (there's nothing
/// to import from Dart), just string constants both sides must agree on.
class PocConfig {
  static const roleDialer = 'DIALER';
  static const roleRecorder = 'RECORDER';
}
