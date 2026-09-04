import 'package:freezed_annotation/freezed_annotation.dart';

part 'apk_download_state.freezed.dart';

@freezed
class ApkDownloadState with _$ApkDownloadState {
  const factory ApkDownloadState.idle() = _Idle;
  const factory ApkDownloadState.downloading({required double progress}) = _Downloading;
  const factory ApkDownloadState.permissionNeeded({required String filePath}) = _PermissionNeeded;
  const factory ApkDownloadState.installLaunched({required String filePath}) = _InstallLaunched;
  const factory ApkDownloadState.error({required String message}) = _Error;
}
