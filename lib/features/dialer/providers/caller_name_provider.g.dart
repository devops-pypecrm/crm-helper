// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caller_name_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$callerDisplayNameHash() => r'16fddf95ff20368d03ba77c1f6d2652ecb3257c1';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Resolves a phone number to a display name for the in-call/incoming-call/
/// call-log screens — CRM lead first (the more relevant identity for a
/// sales call), falling back to the phone's own contacts. Returns null
/// (render the raw number) if neither matches.
///
/// Copied from [callerDisplayName].
@ProviderFor(callerDisplayName)
const callerDisplayNameProvider = CallerDisplayNameFamily();

/// Resolves a phone number to a display name for the in-call/incoming-call/
/// call-log screens — CRM lead first (the more relevant identity for a
/// sales call), falling back to the phone's own contacts. Returns null
/// (render the raw number) if neither matches.
///
/// Copied from [callerDisplayName].
class CallerDisplayNameFamily extends Family<AsyncValue<String?>> {
  /// Resolves a phone number to a display name for the in-call/incoming-call/
  /// call-log screens — CRM lead first (the more relevant identity for a
  /// sales call), falling back to the phone's own contacts. Returns null
  /// (render the raw number) if neither matches.
  ///
  /// Copied from [callerDisplayName].
  const CallerDisplayNameFamily();

  /// Resolves a phone number to a display name for the in-call/incoming-call/
  /// call-log screens — CRM lead first (the more relevant identity for a
  /// sales call), falling back to the phone's own contacts. Returns null
  /// (render the raw number) if neither matches.
  ///
  /// Copied from [callerDisplayName].
  CallerDisplayNameProvider call(String number) {
    return CallerDisplayNameProvider(number);
  }

  @override
  CallerDisplayNameProvider getProviderOverride(
    covariant CallerDisplayNameProvider provider,
  ) {
    return call(provider.number);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'callerDisplayNameProvider';
}

/// Resolves a phone number to a display name for the in-call/incoming-call/
/// call-log screens — CRM lead first (the more relevant identity for a
/// sales call), falling back to the phone's own contacts. Returns null
/// (render the raw number) if neither matches.
///
/// Copied from [callerDisplayName].
class CallerDisplayNameProvider extends AutoDisposeFutureProvider<String?> {
  /// Resolves a phone number to a display name for the in-call/incoming-call/
  /// call-log screens — CRM lead first (the more relevant identity for a
  /// sales call), falling back to the phone's own contacts. Returns null
  /// (render the raw number) if neither matches.
  ///
  /// Copied from [callerDisplayName].
  CallerDisplayNameProvider(String number)
    : this._internal(
        (ref) => callerDisplayName(ref as CallerDisplayNameRef, number),
        from: callerDisplayNameProvider,
        name: r'callerDisplayNameProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$callerDisplayNameHash,
        dependencies: CallerDisplayNameFamily._dependencies,
        allTransitiveDependencies:
            CallerDisplayNameFamily._allTransitiveDependencies,
        number: number,
      );

  CallerDisplayNameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.number,
  }) : super.internal();

  final String number;

  @override
  Override overrideWith(
    FutureOr<String?> Function(CallerDisplayNameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CallerDisplayNameProvider._internal(
        (ref) => create(ref as CallerDisplayNameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        number: number,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String?> createElement() {
    return _CallerDisplayNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CallerDisplayNameProvider && other.number == number;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, number.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CallerDisplayNameRef on AutoDisposeFutureProviderRef<String?> {
  /// The parameter `number` of this provider.
  String get number;
}

class _CallerDisplayNameProviderElement
    extends AutoDisposeFutureProviderElement<String?>
    with CallerDisplayNameRef {
  _CallerDisplayNameProviderElement(super.provider);

  @override
  String get number => (origin as CallerDisplayNameProvider).number;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
