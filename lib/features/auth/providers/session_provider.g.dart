// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionControllerHash() => r'897c77f90504369ec1647d060bc5b78c14f25a22';

/// Single source of truth for "who is logged in" — the login screen, the
/// status screen, and the Dio interceptor's 401 handler all watch this.
/// Mirrors Dad-mobile/lib/features/auth/providers/session_provider.dart,
/// with one addition: login/logout also push/clear the JWT into the native
/// engine's own storage (see [_syncNativeAuth]) so CallMonitorService and
/// CallSyncWorker can authenticate on their own, independent of whether
/// this Dart isolate is even alive.
///
/// Copied from [SessionController].
@ProviderFor(SessionController)
final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, UserSession?>.internal(
      SessionController.new,
      name: r'sessionControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sessionControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SessionController = AsyncNotifier<UserSession?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
