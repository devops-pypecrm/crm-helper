import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/app_release_repository.dart';
import '../domain/app_release.dart';

part 'app_update_provider.g.dart';

/// Swallows every failure to `null` — a broken update check must never
/// block or error out anything else in this app.
@riverpod
Future<AppRelease?> latestHelperRelease(AutoDisposeFutureProviderRef<AppRelease?> ref) async {
  try {
    return await ref.watch(appReleaseRepositoryProvider).getLatestRelease();
  } catch (_) {
    return null;
  }
}

@riverpod
Future<PackageInfo> currentPackageInfo(AutoDisposeFutureProviderRef<PackageInfo> ref) =>
    PackageInfo.fromPlatform();

/// Non-null only when the server's `versionCode` is strictly newer than
/// this running build's own build number.
@riverpod
Future<AppRelease?> availableUpdate(AutoDisposeFutureProviderRef<AppRelease?> ref) async {
  final release = await ref.watch(latestHelperReleaseProvider.future);
  if (release == null) return null;

  final info = await ref.watch(currentPackageInfoProvider.future);
  final currentBuildNumber = int.tryParse(info.buildNumber) ?? 0;

  return release.versionCode > currentBuildNumber ? release : null;
}
