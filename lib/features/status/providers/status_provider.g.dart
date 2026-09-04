// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$enginePermissionsHash() => r'5afa07b82e500af3e85d62509b8c6f0c3c34369e';

/// One-shot read of the Phase 1 runtime-permission grants, used to show a
/// plain "Call log history access: Granted" line on the Status screen —
/// this permission is requested as part of the same onboarding "Required
/// permissions" bundle as everything else, so there's no separate grant
/// step for it, but its status wasn't visible anywhere outside onboarding.
///
/// Copied from [enginePermissions].
@ProviderFor(enginePermissions)
final enginePermissionsProvider =
    AutoDisposeFutureProvider<Map<String, bool>>.internal(
      enginePermissions,
      name: r'enginePermissionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$enginePermissionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EnginePermissionsRef = AutoDisposeFutureProviderRef<Map<String, bool>>;
String _$engineStatusControllerHash() =>
    r'be41cf1c625fec87dbf9acce9252263dd164f13e';

/// Polls the native engine's status every few seconds while the status
/// screen is open — there's no push channel from native to Dart in Phase 1
/// (the engine keeps running whether or not this screen is watching), so
/// polling is the simplest way to reflect what it's doing.
///
/// Copied from [EngineStatusController].
@ProviderFor(EngineStatusController)
final engineStatusControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      EngineStatusController,
      EngineStatus
    >.internal(
      EngineStatusController.new,
      name: r'engineStatusControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$engineStatusControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EngineStatusController = AutoDisposeAsyncNotifier<EngineStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
