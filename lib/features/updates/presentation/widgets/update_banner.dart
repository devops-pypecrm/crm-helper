import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/premium_button.dart';
import '../../providers/app_update_provider.dart';
import '../screens/update_download_screen.dart';

/// Sits at the top of the Home screen when a newer build is published — a
/// lightweight "update available, tap to download" teaser. The actual
/// download/install flow (progress %, live speed, install + reopen-installer
/// buttons) lives in [UpdateDownloadScreen]; this banner's only job is to
/// get the user there.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAsync = ref.watch(availableUpdateProvider);
    final release = updateAsync.valueOrNull;
    if (release == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PremiumCard(
        color: kBrandSurface,
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
            const SizedBox(height: 14),
            PrimaryButton(
              icon: Icons.download_outlined,
              label: 'Download & Install',
              onPressed: () => Navigator.of(context).push(
                AppPageRoute(builder: (_) => UpdateDownloadScreen(release: release)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08);
  }
}
