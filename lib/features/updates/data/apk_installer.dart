import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'apk_installer.g.dart';

@Riverpod(keepAlive: true)
ApkInstaller apkInstaller(ApkInstallerRef ref) => const ApkInstaller();

/// Dart-side handle to `MainActivity.kt`'s install MethodChannel — same
/// pattern as Dad-mobile/lib/features/app_updates/data/apk_installer.dart.
class ApkInstaller {
  const ApkInstaller();

  static const _channel = MethodChannel('com.pypecrm.recorder/installer');

  Future<bool> canRequestInstalls() async =>
      (await _channel.invokeMethod<bool>('canRequestInstalls')) ?? false;

  Future<void> openInstallPermissionSettings() => _channel.invokeMethod('openInstallPermissionSettings');

  Future<void> installApk(String filePath) => _channel.invokeMethod('installApk', {'filePath': filePath});
}
