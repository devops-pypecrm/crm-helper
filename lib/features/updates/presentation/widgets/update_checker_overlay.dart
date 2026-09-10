import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/app_release.dart';
import '../../providers/app_update_provider.dart';
import '../../providers/dismissed_update_provider.dart';
import '../screens/updates_screen.dart';

/// Zero-pixel widget mounted once at the app's outer level (see app.dart's
/// MaterialApp.builder) so the update check runs exactly once per app
/// session regardless of which of the 3 screens (login/onboarding/status)
/// is currently showing — matches Dad-mobile's "invisible checker" pattern.
/// Unlike [UpdateBanner] (which only ever renders if the user happens to
/// open the Status screen), this proactively pops up a dialog the moment a
/// non-dismissed update is found.
class UpdateCheckerOverlay extends ConsumerWidget {
  const UpdateCheckerOverlay({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AppRelease?>>(pendingUpdatePromptProvider, (previous, next) {
      final release = next.valueOrNull;
      if (release == null) return;
      // Guard against re-showing if this listener happens to fire again
      // (e.g. a rebuild) while the dialog from the first firing is still
      // up — the navigator's own overlay already has one route for it.
      final navState = navigatorKey.currentState;
      if (navState == null) return;
      final route = navState.overlay?.context;
      if (route == null) return;
      _showUpdateDialog(route, ref, release);
    });

    return const SizedBox.shrink();
  }

  void _showUpdateDialog(BuildContext context, WidgetRef ref, AppRelease release) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update available — v${release.versionName}'),
        content: SingleChildScrollView(
          child: Text(
            release.releaseNotes.isNotEmpty
                ? release.releaseNotes
                : 'A newer version of PypeCRM Helper is available.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(dismissedUpdateVersionProvider.notifier).dismiss(release.versionCode);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Later'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kBrandColor),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              navigatorKey.currentState?.push(
                MaterialPageRoute<void>(builder: (_) => const UpdatesScreen()),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
