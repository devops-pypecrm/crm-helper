import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_button.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../providers/app_update_provider.dart';
import '../widgets/update_banner.dart';

/// Always-reachable "Updates" page — separate from [UpdateBanner], which
/// only ever renders when a newer build is already known about. This is
/// the destination the Status screen's AppBar action opens, so there's a
/// visible place to manually check for/install an update even when none is
/// currently pending, not just a banner that appears on its own.
class UpdatesScreen extends ConsumerWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfoAsync = ref.watch(currentPackageInfoProvider);
    final updateAsync = ref.watch(availableUpdateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Updates')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(latestHelperReleaseProvider);
          await ref.read(availableUpdateProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            packageInfoAsync.when(
              data: (info) => PremiumCard(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: kBrandSurface, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.info_outline, color: kBrandColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Installed version', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            '${info.version} (build ${info.buildNumber})',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            const UpdateBanner(),
            updateAsync.when(
              data: (release) => release == null
                  ? PremiumCard(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, color: kBrandColor, size: 40),
                          const SizedBox(height: 12),
                          const Text(
                            "You're on the latest version",
                            style: TextStyle(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SecondaryButton(
                            label: 'Check again',
                            expand: false,
                            onPressed: () => ref.invalidate(latestHelperReleaseProvider),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 60.ms, duration: 350.ms).slideY(begin: 0.08)
                  : const SizedBox.shrink(),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => PremiumCard(
                child: Text('Could not check for updates: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
