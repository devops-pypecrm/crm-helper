import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_button.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../domain/app_release.dart';
import '../../providers/apk_download_controller.dart';
import '../../providers/apk_download_state.dart';

/// Dedicated download/install page — replaces [UpdateBanner]'s old inline
/// progress bar as the primary download flow. Shows version/release-notes,
/// a live animated progress ring with "X.X MB / Y.Y MB · Z.Z MB/s", an
/// explicit Install button once the file is on disk, and a Reopen-installer
/// recovery button if the user comes back to the app without the OS
/// installer having visibly completed.
class UpdateDownloadScreen extends ConsumerStatefulWidget {
  const UpdateDownloadScreen({super.key, required this.release});

  final AppRelease release;

  @override
  ConsumerState<UpdateDownloadScreen> createState() => _UpdateDownloadScreenState();
}

class _UpdateDownloadScreenState extends ConsumerState<UpdateDownloadScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Starts automatically — the only reason the user is on this page is
    // that they just tapped "Download & Install" on the banner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apkDownloadControllerProvider.notifier).downloadAndInstall();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Android gives this app no reliable callback for "the user closed the
  /// install prompt without confirming it" — the practical proxy is: we
  /// fired the install intent, the app went to the background (the OS
  /// installer took focus), and now the app has resumed while state is
  /// still `installerOpened`. If install had actually succeeded the OS
  /// would normally have killed/replaced this process rather than resuming
  /// it back into the same screen, so landing here again is itself the
  /// signal to offer "Reopen installer".
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {}); // Just nudges a rebuild; the state itself already reflects reality.
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(apkDownloadControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Update')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version ${widget.release.versionName}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                if (widget.release.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(widget.release.releaseNotes, style: const TextStyle(color: Colors.black54)),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStateCard(context, downloadState),
          ),
        ],
      ),
    );
  }

  Widget _buildStateCard(BuildContext context, ApkDownloadState state) {
    return state.when(
      idle: () => const PremiumCard(
        key: ValueKey('idle'),
        child: Center(child: CircularProgressIndicator()),
      ),
      downloading: (progress, bytesReceived, totalBytes, bytesPerSecond) => _DownloadingCard(
        key: const ValueKey('downloading'),
        progress: progress,
        bytesReceived: bytesReceived,
        totalBytes: totalBytes,
        bytesPerSecond: bytesPerSecond,
      ),
      downloaded: (filePath) => _DownloadedCard(key: const ValueKey('downloaded'), filePath: filePath),
      permissionNeeded: (filePath) => _PermissionNeededCard(key: const ValueKey('permission'), filePath: filePath),
      installerOpened: (filePath) =>
          _InstallerOpenedCard(key: const ValueKey('installerOpened'), filePath: filePath),
      error: (message) => _ErrorCard(key: const ValueKey('error'), message: message),
    );
  }
}

class _DownloadingCard extends StatelessWidget {
  const _DownloadingCard({
    super.key,
    required this.progress,
    required this.bytesReceived,
    required this.totalBytes,
    required this.bytesPerSecond,
  });

  final double progress;
  final int bytesReceived;
  final int totalBytes;
  final double bytesPerSecond;

  String _mb(num bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 10,
                    backgroundColor: kBrandSurface,
                    valueColor: const AlwaysStoppedAnimation(kBrandColor),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            totalBytes > 0
                ? '${_mb(bytesReceived)} MB / ${_mb(totalBytes)} MB · ${_mb(bytesPerSecond)} MB/s'
                : 'Starting download…',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _DownloadedCard extends ConsumerWidget {
  const _DownloadedCard({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumCard(
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: kBrandColor, size: 48).animate().scale(
                duration: 350.ms,
                curve: Curves.easeOutBack,
                begin: const Offset(0.6, 0.6),
              ),
          const SizedBox(height: 12),
          const Text('Download complete', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          PrimaryButton(
            icon: Icons.system_update_alt,
            label: 'Install',
            onPressed: () => ref.read(apkDownloadControllerProvider.notifier).installNow(filePath),
          ),
        ],
      ),
    );
  }
}

class _PermissionNeededCard extends ConsumerWidget {
  const _PermissionNeededCard({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Allow PypeCRM Helper to install updates, then come back and tap Install.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: 'Open settings',
            onPressed: () => ref.read(apkDownloadControllerProvider.notifier).openPermissionSettings(),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Install',
            onPressed: () => ref.read(apkDownloadControllerProvider.notifier).retryInstall(filePath),
          ),
        ],
      ),
    );
  }
}

class _InstallerOpenedCard extends ConsumerWidget {
  const _InstallerOpenedCard({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumCard(
      child: Column(
        children: [
          const Icon(Icons.system_update_alt, color: kBrandColor, size: 40),
          const SizedBox(height: 10),
          const Text(
            'Installer opened — follow the prompt to finish updating.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            "Back here and nothing happened? The installer screen may have "
            'closed before you confirmed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            icon: Icons.refresh,
            label: 'Reopen installer',
            onPressed: () => ref.read(apkDownloadControllerProvider.notifier).reopenInstaller(filePath),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _ErrorCard extends ConsumerWidget {
  const _ErrorCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Couldn't update: $message",
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Retry',
            onPressed: () => ref.read(apkDownloadControllerProvider.notifier).downloadAndInstall(),
          ),
        ],
      ),
    );
  }
}
