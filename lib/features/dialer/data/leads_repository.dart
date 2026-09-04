import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/dio_provider.dart';
import '../domain/lead_match.dart';

part 'leads_repository.g.dart';

/// Fetches the CRM leads assigned to the current user so the dialer can
/// match phone numbers to names locally.
class LeadsRepository {
  const LeadsRepository(this._dio);
  final Dio _dio;

  /// Fetches all accessible leads. In a real app this might be paginated or
  /// use a sync engine, but for this field-companion app, /api/android/leads
  /// returns a compact list of just the fields needed for caller ID.
  Future<List<LeadMatch>> getAndroidLeads() async {
    final response = await _dio.get('/api/android/leads');
    final data = response.data as List;
    return data.map((j) => LeadMatch.fromJson(j as Map<String, dynamic>)).toList();
  }
}

@riverpod
LeadsRepository leadsRepository(Ref ref) {
  return LeadsRepository(ref.watch(dioProvider));
}
