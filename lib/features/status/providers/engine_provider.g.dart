// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$callRecordingEngineHash() =>
    r'831c1713a5ffa02b0d5b44c37c98b119f83868e0';

/// Single instance of the native plugin handle — everything that needs to
/// talk to the call-monitoring engine (session_provider on login/logout,
/// the status screen, the onboarding wizard) goes through this.
///
/// Copied from [callRecordingEngine].
@ProviderFor(callRecordingEngine)
final callRecordingEngineProvider = Provider<CallRecordingEngine>.internal(
  callRecordingEngine,
  name: r'callRecordingEngineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$callRecordingEngineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CallRecordingEngineRef = ProviderRef<CallRecordingEngine>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
