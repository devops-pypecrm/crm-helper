import 'package:freezed_annotation/freezed_annotation.dart';

part 'apk_download_state.freezed.dart';

@freezed
class ApkDownloadState with _$ApkDownloadState {
  const factory ApkDownloadState.idle() = _Idle;

  /// [progress] is kept (0.0-1.0) alongside the raw byte counts for any
  /// caller that only needs a ratio; [bytesPerSecond] is a smoothed instant
  /// rate (see `ApkDownloadController`'s doc comment on how it's computed),
  /// not a running average over the whole download.
  const factory ApkDownloadState.downloading({
    required double progress,
    required int bytesReceived,
    required int totalBytes,
    required double bytesPerSecond,
  }) = _Downloading;

  /// Reached once the file is fully on disk but *before* the install intent
  /// fires — the old behavior auto-fired the installer the instant the
  /// download finished, which gave the user no visible "it's ready" moment.
  const factory ApkDownloadState.downloaded({required String filePath}) = _Downloaded;

  const factory ApkDownloadState.permissionNeeded({required String filePath}) = _PermissionNeeded;

  /// We've fired `ACTION_VIEW` for the system installer and the user may
  /// still be sitting on that OS screen. Distinct from any later "it
  /// actually installed" state because Android gives this app no callback
  /// for that — see `ApkDownloadController.reopenInstaller`'s doc comment.
  const factory ApkDownloadState.installerOpened({required String filePath}) = _InstallerOpened;

  const factory ApkDownloadState.error({required String message}) = _Error;
}
