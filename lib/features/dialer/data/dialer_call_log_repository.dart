import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/call_record.dart';

/// In-memory + file-backed store for the dialer's own recent-call list.
/// Uses path_provider (already a direct dependency) to write a JSON file
/// in the app's support directory. Max 200 entries, newest-first.
class DialerCallLogRepository {
  DialerCallLogRepository._();
  static final DialerCallLogRepository instance = DialerCallLogRepository._();

  static const _fileName = 'dialer_call_log.json';
  static const _maxEntries = 200;

  List<CallRecord>? _cache;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<CallRecord>> getAll() async {
    if (_cache != null) return List.unmodifiable(_cache!);
    return _loadFromFile();
  }

  Future<void> add(CallRecord record) async {
    final all = await getAll().then((l) => l.toList());
    all.insert(0, record);
    if (all.length > _maxEntries) all.removeRange(_maxEntries, all.length);
    _cache = all;
    await _saveToFile(all);
  }

  Future<void> clear() async {
    _cache = [];
    final f = await _file();
    if (await f.exists()) await f.delete();
  }

  Future<List<CallRecord>> _loadFromFile() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final raw = await f.readAsString();
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(CallRecord.fromJson)
          .toList();
      _cache = list;
      return List.unmodifiable(list);
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveToFile(List<CallRecord> records) async {
    final f = await _file();
    await f.writeAsString(
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }
}
