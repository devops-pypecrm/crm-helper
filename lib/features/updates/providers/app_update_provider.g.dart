// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$latestHelperReleaseHash() =>
    r'ffdc1753a935a327e0db2672beebbb5b46126a13';

/// Swallows every failure to `null` — a broken update check must never
/// block or error out anything else in this app.
///
/// Copied from [latestHelperRelease].
@ProviderFor(latestHelperRelease)
final latestHelperReleaseProvider =
    AutoDisposeFutureProvider<AppRelease?>.internal(
      latestHelperRelease,
      name: r'latestHelperReleaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$latestHelperReleaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LatestHelperReleaseRef = AutoDisposeFutureProviderRef<AppRelease?>;
String _$currentPackageInfoHash() =>
    r'7e59829d6e685a0494b8bb96e3e9654fa274b4e7';

/// See also [currentPackageInfo].
@ProviderFor(currentPackageInfo)
final currentPackageInfoProvider =
    AutoDisposeFutureProvider<PackageInfo>.internal(
      currentPackageInfo,
      name: r'currentPackageInfoProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentPackageInfoHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentPackageInfoRef = AutoDisposeFutureProviderRef<PackageInfo>;
String _$availableUpdateHash() => r'061d9b21c262369087fa87321addd55b8c7ab334';

/// Non-null only when the server's `versionCode` is strictly newer than
/// this running build's own build number.
///
/// Copied from [availableUpdate].
@ProviderFor(availableUpdate)
final availableUpdateProvider = AutoDisposeFutureProvider<AppRelease?>.internal(
  availableUpdate,
  name: r'availableUpdateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableUpdateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableUpdateRef = AutoDisposeFutureProviderRef<AppRelease?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
