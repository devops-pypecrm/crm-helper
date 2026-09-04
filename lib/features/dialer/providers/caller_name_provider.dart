import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/status/providers/engine_provider.dart';
import 'lead_search_provider.dart';

part 'caller_name_provider.g.dart';

/// Resolves a phone number to a display name for the in-call/incoming-call/
/// call-log screens — CRM lead first (the more relevant identity for a
/// sales call), falling back to the phone's own contacts. Returns null
/// (render the raw number) if neither matches.
@riverpod
Future<String?> callerDisplayName(AutoDisposeFutureProviderRef<String?> ref, String number) async {
  final normalized = number.replaceAll(RegExp(r'\D'), '');
  if (normalized.length < 6) return null;

  final leads = await ref.watch(cachedLeadsProvider.future);
  for (final lead in leads) {
    final leadDigits = lead.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (leadDigits.isNotEmpty &&
        (leadDigits.endsWith(normalized) || normalized.endsWith(leadDigits))) {
      return lead.name;
    }
  }

  try {
    return await ref.read(callRecordingEngineProvider).lookupContactName(number);
  } catch (_) {
    return null;
  }
}
