import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/leads_repository.dart';
import '../domain/lead_match.dart';
import 'dialer_provider.dart';
import 'dialer_state.dart';

part 'lead_search_provider.g.dart';

/// Fetches and caches the list of leads once on startup.
@Riverpod(keepAlive: true)
Future<List<LeadMatch>> cachedLeads(Ref ref) async {
  return ref.watch(leadsRepositoryProvider).getAndroidLeads();
}

/// Computes the best matching lead for the current dialer state (the digits
/// typed so far, or the active call number).
@riverpod
LeadMatch? currentLeadMatch(Ref ref) {
  final dialerState = ref.watch(dialerProvider);
  final leadsAsync = ref.watch(cachedLeadsProvider);

  final leads = leadsAsync.valueOrNull;
  if (leads == null || leads.isEmpty) return null;

  String query = '';
  if (dialerState is DialerIdle) {
    query = dialerState.digits;
  } else if (dialerState is DialerDialing) {
    query = dialerState.number;
  } else if (dialerState is DialerInCall) {
    query = dialerState.number;
  } else if (dialerState is DialerIncoming) {
    query = dialerState.number;
  }

  if (query.isEmpty) return null;

  // Simple suffix matching (last 7-10 digits usually enough for local numbers).
  // In a production app you'd use a real phonenumber parsing library.
  final normalizedQuery = query.replaceAll(RegExp(r'\D'), '');
  if (normalizedQuery.length < 6) return null; // Too short to accurately match

  for (final lead in leads) {
    final normalizedLeadNumber = lead.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (normalizedLeadNumber.endsWith(normalizedQuery) ||
        normalizedQuery.endsWith(normalizedLeadNumber)) {
      return lead;
    }
  }

  return null;
}
