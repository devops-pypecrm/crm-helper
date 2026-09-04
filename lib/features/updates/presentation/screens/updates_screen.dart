import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
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
          padding: const EdgeInsets.all(16),
          children: [
            packageInfoAsync.when(
              data: (info) => Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline, color: kBrandColor),
                  title: const Text('Installed version'),
                  subtitle: Text('${info.version} (build ${info.buildNumber})'),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            const UpdateBanner(),
            updateAsync.when(
              data: (release) => release == null
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline, color: kBrandColor, size: 40),
                            const SizedBox(height: 12),
                            const Text(
                              "You're on the latest version",
                              style: TextStyle(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                ref.invalidate(latestHelperReleaseProvider);
                              },
                              child: const Text('Check again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Could not check for updates: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
