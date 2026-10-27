import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../status/providers/engine_provider.dart';

/// Native-recording event names this screen cares about — written by
/// `NativeRecordingScanner.kt` on every Tier 0 scan attempt (a scan runs
/// once per completed call, regardless of outcome).
const _tier0MatchFound = 'TIER0_MATCH_FOUND';
const _tier0NoMatch = 'TIER0_NO_MATCH';

enum _Tier0DiagnosticState { working, notFinding, noData }

class _Tier0Diagnostic {
  const _Tier0Diagnostic(this.state, this.timestamp);

  final _Tier0DiagnosticState state;
  final DateTime? timestamp;
}

/// Split out of the old do-everything Status screen: Permissions, sign-out,
/// and the Tier 0 native-recording diagnostic now live here, leaving Home
/// to just the monitoring toggle + stats.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<_Tier0Diagnostic>? _diagnosticFuture;

  @override
  void initState() {
    super.initState();
    _loadDiagnostic();
  }

  void _loadDiagnostic() {
    setState(() {
      _diagnosticFuture = _readDiagnostic();
    });
  }

  Future<_Tier0Diagnostic> _readDiagnostic() async {
    final engine = ref.read(callRecordingEngineProvider);
    final log = await engine.getEngineDebugLog();
    for (final entry in log) {
      final event = entry['event'] as String?;
      if (event == _tier0MatchFound) {
        return _Tier0Diagnostic(_Tier0DiagnosticState.working, _entryTime(entry));
      }
      if (event == _tier0NoMatch) {
        return _Tier0Diagnostic(_Tier0DiagnosticState.notFinding, _entryTime(entry));
      }
    }
    return const _Tier0Diagnostic(_Tier0DiagnosticState.noData, null);
  }

  DateTime? _entryTime(Map<String, Object?> entry) {
    final millis = (entry['timestampMillis'] as num?)?.toInt();
    return millis == null || millis <= 0 ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Monitoring will stop on this device until you sign back in.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionControllerProvider.notifier).logout();
      // logout() flips sessionControllerProvider to null immediately, which
      // makes the root _AuthGate (app.dart) rebuild to LoginScreen — but
      // that's the `home` route sitting underneath whatever's pushed on top
      // of it (Settings, and Status below that). Without popping back to it
      // explicitly, this screen just stays on top showing stale "signed in"
      // UI until the next cold start rebuilds the Navigator from scratch,
      // which is why sign-out looked like it "needed an app restart" to
      // take effect.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader('Account'),
          PremiumCard(
            onTap: () => Navigator.of(context).push(
              AppPageRoute(builder: (_) => const OnboardingScreen(fromStatusScreen: true)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: kBrandSurface, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.center,
                  child: const Icon(Icons.verified_user_outlined, color: kBrandColor, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Permissions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      SizedBox(height: 2),
                      Text('Review required permissions', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08),
          const SizedBox(height: 10),
          PremiumCard(
            onTap: _confirmLogout,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.logout, color: Theme.of(context).colorScheme.error, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 60.ms, duration: 350.ms).slideY(begin: 0.08),
          const SizedBox(height: 24),
          SectionHeader(
            'Native recording check',
            trailing: TextButton(onPressed: _loadDiagnostic, child: const Text('Check again')),
          ),
          FutureBuilder<_Tier0Diagnostic>(
            future: _diagnosticFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const PremiumCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              return _Tier0DiagnosticCard(diagnostic: snapshot.data!, dateFormat: dateFormat);
            },
          ).animate().fadeIn(delay: 120.ms, duration: 350.ms).slideY(begin: 0.08),
        ],
      ),
    );
  }
}

class _Tier0DiagnosticCard extends StatelessWidget {
  const _Tier0DiagnosticCard({required this.diagnostic, required this.dateFormat});

  final _Tier0Diagnostic diagnostic;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final String title;
    final String? subtitle;

    switch (diagnostic.state) {
      case _Tier0DiagnosticState.working:
        icon = Icons.check_circle;
        color = kBrandColor;
        title = diagnostic.timestamp == null
            ? 'Working — last confirmed on a recent call'
            : 'Working — last confirmed on a call at ${dateFormat.format(diagnostic.timestamp!)}';
        subtitle = null;
      case _Tier0DiagnosticState.notFinding:
        icon = Icons.error_outline;
        color = Colors.orange;
        title = diagnostic.timestamp == null
            ? 'Not finding recordings'
            : 'Not finding recordings — last call checked at ${dateFormat.format(diagnostic.timestamp!)} found nothing';
        subtitle = "This is expected if this phone's own dialer/recorder app "
            "doesn't auto-record calls — not every phone has that feature.";
      case _Tier0DiagnosticState.noData:
        icon = Icons.info_outline;
        color = Colors.black54;
        title = 'No data yet';
        subtitle = 'Place a test call, then check again.';
    }

    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
