import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/apk_installer.dart';
import '../../providers/apk_download_controller.dart';
import '../../providers/app_update_provider.dart';

/// Sits at the top of the Status screen when a newer build is published —
/// this app has no push notifications wired up (see this feature's own
/// build notes), so it's checked on every app open/pull-to-refresh instead
/// of appearing as a popup. Handles the whole download -> install-permission
/// -> hand-off-to-installer flow inline, matching Dad-mobile's Updates
/// screen but condensed into one card for this 3-screen utility app.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAsync = ref.watch(availableUpdateProvider);
    final release = updateAsync.valueOrNull;
    if (release == null) return const SizedBox.shrink();

    final downloadState = ref.watch(apkDownloadControllerProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBrandSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBrandColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.system_update_outlined, color: kBrandColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Update available — v${release.versionName}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (release.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(release.releaseNotes, style: theme.textTheme.bodySmall, softWrap: true),
            ],
            const SizedBox(height: 12),
            downloadState.when(
              idle: () => SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Download & Install'),
                  onPressed: () => ref.read(apkDownloadControllerProvider.notifier).downloadAndInstall(),
                ),
              ),
              downloading: (progress) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(value: progress, minHeight: 8, color: kBrandColor),
                  ),
                  const SizedBox(height: 6),
                  Text('${(progress * 100).round()}%', style: theme.textTheme.labelSmall),
                ],
              ),
              permissionNeeded: (filePath) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Allow PypeCRM Helper to install updates, then come back and tap Install.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref.read(apkInstallerProvider).openInstallPermissionSettings(),
                          child: const Text('Open Settings'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              ref.read(apkDownloadControllerProvider.notifier).retryInstall(filePath),
                          child: const Text('Install'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              installLaunched: (filePath) => Text(
                'Installer opened — follow the prompt to finish updating.',
                style: theme.textTheme.bodySmall?.copyWith(color: kBrandColor, fontWeight: FontWeight.w600),
              ),
              error: (message) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Couldn't update: $message",
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ref.read(apkDownloadControllerProvider.notifier).downloadAndInstall(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
