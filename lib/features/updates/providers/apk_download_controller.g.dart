// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apk_download_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$apkDownloadControllerHash() =>
    r'c393e329c8826b216e8a672c9158d02bfffa731e';

/// Downloads the current .apk into this app's own cache dir and hands it to
/// the system installer. Mirrors Dad-mobile's
/// `ApkDownloadController` — same flow, same reasoning (see that file's
/// doc comment and pypecrm/APP_UPDATE_SYSTEM.md).
///
/// Copied from [ApkDownloadController].
@ProviderFor(ApkDownloadController)
final apkDownloadControllerProvider =
    AutoDisposeNotifierProvider<
      ApkDownloadController,
      ApkDownloadState
    >.internal(
      ApkDownloadController.new,
      name: r'apkDownloadControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$apkDownloadControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ApkDownloadController = AutoDisposeNotifier<ApkDownloadState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
