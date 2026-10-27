import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_button.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../status/providers/engine_provider.dart';
import '../../../status/providers/status_provider.dart';
import '../../../status/presentation/screens/status_screen.dart';

/// Walks the user through the one thing Tier 0/Tier 4 actually need to run:
/// the runtime permissions (READ_CALL_LOG, READ_PHONE_STATE, etc.).
/// [fromStatusScreen] just changes what happens on "Done" — pop back vs.
/// replace into [StatusScreen] on first run.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.fromStatusScreen = false});

  final bool fromStatusScreen;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  Map<String, bool> _permissions = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final engine = ref.read(callRecordingEngineProvider);
    final permissions = await engine.checkPermissions();
    if (!mounted) return;
    setState(() {
      _permissions = permissions;
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
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'These let PypeCRM Helper notice calls, find recordings your '
                  "phone's own call recorder already made, and keep syncing in the "
                  'background even when this app is closed.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1),
                const SizedBox(height: 20),
                _OnboardingStep(
                  title: 'Required permissions',
                  subtitle: _permissionsSubtitle(),
                  done: _allPermissionsGranted,
                  actionLabel: 'Grant',
                  onAction: _requestPermissions,
                ).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.1),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: _readyToFinish ? 'Start monitoring' : 'Grant permissions to continue',
                  onPressed: _readyToFinish ? _finish : null,
                ).animate().fadeIn(delay: 140.ms, duration: 350.ms).slideY(begin: 0.1),
                if (!_readyToFinish) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(onPressed: _finish, child: const Text('Skip for now')),
                  ),
                ],
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
  final bool done;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Icon(
              done ? Icons.check_circle : Icons.error_outline,
              key: ValueKey(done),
              color: done ? kBrandColor : Colors.orange,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          if (!done) SecondaryButton(label: actionLabel, onPressed: onAction, expand: false),
        ],
      ),
    );
  }
}
