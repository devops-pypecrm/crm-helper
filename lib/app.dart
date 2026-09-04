import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/providers/session_provider.dart';
import 'features/dialer/presentation/screens/call_log_screen.dart';
import 'features/dialer/presentation/screens/dialer_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/status/presentation/screens/status_screen.dart';
import 'features/status/providers/engine_provider.dart';

class CallRecorderApp extends StatelessWidget {
  const CallRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PypeCRM Helper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

/// No router package for a small app — a single gate widget that swaps
/// between login/onboarding/main-shell based on [sessionControllerProvider].
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionControllerProvider);

    return sessionAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => const LoginScreen(),
      data: (session) {
        if (session == null) return const LoginScreen();
        return _PostLoginGate(key: ValueKey(session.id));
      },
    );
  }
}

/// Decides between onboarding and the main bottom-nav shell once — permissions
/// granted implies onboarding was already completed at some point, so a
/// returning already-set-up user doesn't have to click through it on every
/// cold start. Keyed on the user id so switching accounts on the same
/// device re-checks rather than showing a stale decision.
class _PostLoginGate extends ConsumerStatefulWidget {
  const _PostLoginGate({super.key});

  @override
  ConsumerState<_PostLoginGate> createState() => _PostLoginGateState();
}

class _PostLoginGateState extends ConsumerState<_PostLoginGate> {
  late final Future<bool> _onboardingNeeded = _checkOnboardingNeeded();

  /// Defaults to "onboarding needed" on any failure (including
  /// MissingPluginException on a platform with no native implementation,
  /// e.g. running this Android-only app's Dart layer on web/desktop for a
  /// quick UI check) rather than leaving the caller stuck on an infinite
  /// spinner — onboarding itself can be skipped from there.
  Future<bool> _checkOnboardingNeeded() async {
    try {
      final permissions = await ref.read(callRecordingEngineProvider).checkPermissions();
      return permissions.isEmpty || permissions.values.any((granted) => !granted);
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _onboardingNeeded,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return (snapshot.data ?? true)
            ? const OnboardingScreen()
            : const _MainShell();
      },
    );
  }
}

/// Bottom-navigation shell hosting the three main tabs:
///   0 — Status (existing monitoring/sync status)
///   1 — Dialer (keypad for placing calls)
///   2 — Recent calls (dialer's own call log)
class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _selectedIndex = 0;

  static const _screens = [
    StatusScreen(),
    DialerScreen(),
    CallLogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Status',
          ),
          NavigationDestination(
            icon: Icon(Icons.dialpad_outlined),
            selectedIcon: Icon(Icons.dialpad),
            label: 'Dialer',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Recents',
          ),
        ],
      ),
    );
  }
}

