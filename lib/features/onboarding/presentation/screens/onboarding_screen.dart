import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../advanced/presentation/screens/native_recording_setup_screen.dart';
import '../../../status/providers/engine_provider.dart';
import '../../../status/providers/status_provider.dart';
import '../../../status/presentation/screens/status_screen.dart';

/// Walks the user through everything Tier 0/Tier 4 need to actually run:
/// the Phase 1 runtime permissions, then the battery-optimization exemption
/// and (if this device's manufacturer has one) the OEM auto-start screen —
/// without these, aggressive OEM battery managers silently kill the
/// background service and monitoring just stops working (see the plan's
/// Risks section). [fromStatusScreen] just changes what happens on
/// "Done" — pop back vs. replace into [StatusScreen] on first run.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.fromStatusScreen = false});

  final bool fromStatusScreen;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  Map<String, bool> _permissions = const {};
  bool _ignoringBatteryOptimizations = false;
  bool _accessibilityEnabled = false;
  bool _hasProjectionToken = false;
  bool _whatsAppListenerEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final engine = ref.read(callRecordingEngineProvider);
    final permissions = await engine.checkPermissions();
    final ignoringBattery = await engine.isIgnoringBatteryOptimizations();
    final accessibilityEnabled = await engine.isAccessibilityServiceEnabled();
    final hasProjectionToken = await engine.hasMediaProjectionToken();
    final whatsAppListenerEnabled = await engine.isWhatsAppListenerEnabled();
    if (!mounted) return;
    setState(() {
      _permissions = permissions;
      _ignoringBatteryOptimizations = ignoringBattery;
      _accessibilityEnabled = accessibilityEnabled;
      _hasProjectionToken = hasProjectionToken;
      _whatsAppListenerEnabled = whatsAppListenerEnabled;
      _loading = false;
    });
  }

  bool get _allPermissionsGranted =>
      _permissions.isNotEmpty && _permissions.values.every((granted) => granted);

  bool get _readyToFinish => _allPermissionsGranted;

  Future<void> _requestPermissions() async {
    final engine = ref.read(callRecordingEngineProvider);
    await engine.requestPermissions();
    await _refresh();
  }

  Future<void> _requestBattery() async {
    final engine = ref.read(callRecordingEngineProvider);
    await engine.requestBatteryOptimizationExemption();
    // The system settings screen is a separate Activity — refresh once the
    // user returns rather than assuming the request succeeded.
    await _refresh();
  }

  Future<void> _openAutoStart() async {
    await ref.read(callRecordingEngineProvider).openAutoStartSettings();
  }

  Future<void> _openAccessibilitySettings() async {
    await ref.read(callRecordingEngineProvider).openAccessibilitySettings();
    // The user has to find and toggle it by hand in system Settings —
    // refresh once they return rather than assuming it happened.
    await _refresh();
  }

  Future<void> _requestMediaProjection() async {
    await ref.read(callRecordingEngineProvider).requestMediaProjectionPermission();
    await _refresh();
  }

  Future<void> _openNotificationListenerSettings() async {
    await ref.read(callRecordingEngineProvider).openNotificationListenerSettings();
    // The user has to find and toggle it by hand in system Settings —
    // refresh once they return rather than assuming it happened.
    await _refresh();
  }

  Future<void> _finish() async {
    if (_allPermissionsGranted) {
      await ref.read(callRecordingEngineProvider).startMonitoring();
      ref.invalidate(engineStatusControllerProvider);
    }
    if (!mounted) return;
    if (widget.fromStatusScreen) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StatusScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up call recording')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'These let PypeCRM Helper notice calls, find recordings your '
                  "phone's own call recorder already made, and keep syncing in the "
                  'background even when this app is closed.',
                ),
                const SizedBox(height: 16),
                _OnboardingStep(
                  title: 'Required permissions',
                  subtitle: _permissionsSubtitle(),
                  done: _allPermissionsGranted,
                  actionLabel: 'Grant',
                  onAction: _requestPermissions,
                ),
                _OnboardingStep(
                  title: 'Ignore battery optimizations',
                  subtitle: _ignoringBatteryOptimizations
                      ? 'Enabled — this app will keep running in the background.'
                      : 'Without this, some phones stop monitoring calls in the background.',
                  done: _ignoringBatteryOptimizations,
                  actionLabel: 'Enable',
                  onAction: _requestBattery,
                ),
                _OnboardingStep(
                  title: 'Auto-start / background activity',
                  subtitle: 'Some manufacturers (Xiaomi, Oppo, Vivo, and others) need this '
                      'enabled separately, or they will still kill the background service.',
                  done: null, // Not independently verifiable — always offered.
                  actionLabel: 'Open settings',
                  onAction: _openAutoStart,
                ),
                const SizedBox(height: 24),
                Text('Advanced (optional)', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                const Text(
                  "These improve recording coverage on phones without a built-in call "
                  'recorder, but are more invasive — only enable them if recordings are '
                  "still missing after the setup above.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                _OnboardingStep(
                  title: 'Accessibility service',
                  subtitle: _accessibilityEnabled
                      ? 'Enabled — unlocks an extra in-call audio source on some phones.'
                      : 'Unlocks an extra in-call audio source some phones otherwise block.',
                  done: _accessibilityEnabled,
                  actionLabel: 'Open settings',
                  onAction: _openAccessibilitySettings,
                ),
                _OnboardingStep(
                  title: 'WhatsApp reply sync',
                  subtitle: _whatsAppListenerEnabled
                      ? 'Enabled — inbound WhatsApp replies are logged to the CRM automatically.'
                      : 'Logs a lead\'s WhatsApp replies to the CRM timeline automatically. '
                          'Reads only the notification preview (contact + message text), '
                          'never the full chat.',
                  done: _whatsAppListenerEnabled,
                  actionLabel: 'Open settings',
                  onAction: _openNotificationListenerSettings,
                ),
                _OnboardingStep(
                  title: 'Call audio capture (fallback)',
                  subtitle: _hasProjectionToken
                      ? 'Granted for this session — used only if the above methods fail.'
                      : 'A one-time system prompt, used only if the above methods fail to '
                          'capture a call.',
                  done: _hasProjectionToken,
                  actionLabel: 'Grant',
                  onAction: _requestMediaProjection,
                ),
                _OnboardingStep(
                  title: 'Auto-enable native call recording (Samsung, experimental)',
                  subtitle: 'Tries to switch on the phone\'s own built-in call-recording '
                      'setting so it captures calls itself. Samsung One UI only for now; '
                      'requires accessibility above to be enabled first.',
                  done: null, // Not independently verifiable — always offered.
                  actionLabel: 'Open',
                  onAction: () async {
                    if (!mounted) return;
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NativeRecordingSetupScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _readyToFinish ? _finish : null,
                  child: Text(_readyToFinish ? 'Start monitoring' : 'Grant permissions to continue'),
                ),
                if (!_readyToFinish)
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip for now'),
                  ),
              ],
            ),
    );
  }

  String _permissionsSubtitle() {
    if (_permissions.isEmpty) return 'Checking…';
    final granted = _permissions.values.where((v) => v).length;
    return '$granted of ${_permissions.length} granted';
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  /// null means "no pass/fail state to show" (e.g. a settings screen we
  /// can't verify the outcome of) — shows a neutral icon instead of a
  /// check/cross.
  final bool? done;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          done == null ? Icons.settings_outlined : (done! ? Icons.check_circle : Icons.error_outline),
          color: done == true ? Colors.green : (done == false ? Colors.orange : null),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: (done == true)
            ? null
            : TextButton(onPressed: onAction, child: Text(actionLabel)),
      ),
    );
  }
}
