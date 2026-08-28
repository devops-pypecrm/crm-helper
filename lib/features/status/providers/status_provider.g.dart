// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$engineStatusControllerHash() =>
    r'5540568b7e991085d2e867be6a1c552cd97dcb6f';

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
