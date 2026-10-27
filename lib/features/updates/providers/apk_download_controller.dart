import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/apk_installer.dart';
import '../data/app_release_repository.dart';
import 'apk_download_state.dart';

part 'apk_download_controller.g.dart';

/// Downloads the current .apk into this app's own cache dir and hands it to
/// the system installer. Mirrors Dad-mobile's
/// `ApkDownloadController` — same flow, same reasoning (see that file's
/// doc comment and pypecrm/APP_UPDATE_SYSTEM.md).
@riverpod
class ApkDownloadController extends _$ApkDownloadController {
  @override
  ApkDownloadState build() => const ApkDownloadState.idle();

  /// Last few `(wall-clock time, bytesReceived)` ticks from
  /// `onReceiveProgress`, oldest first — used to smooth the displayed
  /// speed. A single consecutive-tick delta is jumpy (ticks don't arrive on
  /// a fixed schedule — a slow Wi-Fi hiccup between two ticks that are 50ms
  /// apart would otherwise flash a wildly wrong instantaneous rate), so the
  /// rate shown is instead computed across the oldest and newest tick kept
  /// in this short window.
  final List<(DateTime, int)> _speedSamples = [];
  static const _maxSpeedSamples = 5;

  Future<void> downloadAndInstall() async {
    _speedSamples.clear();
    state = const ApkDownloadState.downloading(
      progress: 0,
      bytesReceived: 0,
      totalBytes: 0,
      bytesPerSecond: 0,
    );
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/pypecrm-helper-update.apk';

      await ref.read(appReleaseRepositoryProvider).downloadApk(
            savePath: savePath,
            onProgress: (received, total) {
              if (total <= 0) return;
              state = ApkDownloadState.downloading(
                progress: received / total,
                bytesReceived: received,
                totalBytes: total,
                bytesPerSecond: _trackSpeed(received),
              );
            },
          );

      state = ApkDownloadState.downloaded(filePath: savePath);
    } catch (e) {
      state = ApkDownloadState.error(message: '$e');
    }
  }

  double _trackSpeed(int bytesReceived) {
    final now = DateTime.now();
    _speedSamples.add((now, bytesReceived));
    if (_speedSamples.length > _maxSpeedSamples) _speedSamples.removeAt(0);
    if (_speedSamples.length < 2) return 0;

    final oldest = _speedSamples.first;
    final secondsElapsed = now.difference(oldest.$1).inMilliseconds / 1000;
    if (secondsElapsed <= 0) return 0;
    return (bytesReceived - oldest.$2) / secondsElapsed;
  }

  /// Called from the `downloaded` state once the user taps "Install" — the
  /// download completing no longer auto-triggers this.
  Future<void> installNow(String filePath) => _attemptInstall(filePath);

  Future<void> retryInstall(String filePath) => _attemptInstall(filePath);

  Future<void> _attemptInstall(String filePath) async {
    final installer = ref.read(apkInstallerProvider);
    final canInstall = await installer.canRequestInstalls();
    if (!canInstall) {
      state = ApkDownloadState.permissionNeeded(filePath: filePath);
      return;
    }
    try {
      await installer.installApk(filePath);
      state = ApkDownloadState.installerOpened(filePath: filePath);
    } catch (e) {
      state = ApkDownloadState.error(message: '$e');
    }
  }

  /// Re-fires the same install intent using the file path retained from
  /// `installerOpened` — the practical recovery path for "the user backed
  /// out of the OS installer screen without confirming or cancelling it",
  /// which Android gives this app no direct callback for (see
  /// `update_download_screen.dart`'s lifecycle-resume detection).
  Future<void> reopenInstaller(String filePath) => _attemptInstall(filePath);

  Future<void> openPermissionSettings() => ref.read(apkInstallerProvider).openInstallPermissionSettings();

  void reset() => state = const ApkDownloadState.idle();
}
