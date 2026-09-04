// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cachedLeadsHash() => r'41aa0133132dfd422091a37c45885c2d787d2b5b';

/// Fetches and caches the list of leads once on startup.
///
/// Copied from [cachedLeads].
@ProviderFor(cachedLeads)
final cachedLeadsProvider = FutureProvider<List<LeadMatch>>.internal(
  cachedLeads,
  name: r'cachedLeadsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cachedLeadsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CachedLeadsRef = FutureProviderRef<List<LeadMatch>>;
String _$currentLeadMatchHash() => r'9d32e27675dc63e54b287920a9c066929004b3f0';

/// Computes the best matching lead for the current dialer state (the digits
/// typed so far, or the active call number).
///
/// Copied from [currentLeadMatch].
@ProviderFor(currentLeadMatch)
final currentLeadMatchProvider = AutoDisposeProvider<LeadMatch?>.internal(
  currentLeadMatch,
  name: r'currentLeadMatchProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentLeadMatchHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentLeadMatchRef = AutoDisposeProviderRef<LeadMatch?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
