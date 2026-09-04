import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/dialer_call_log_repository.dart';
import '../../domain/call_record.dart';
import '../../providers/dialer_provider.dart';

enum _LogFilter { all, missed, incoming, outgoing }

/// Recent-calls list — calls placed or received through this app's dialer.
/// Separate from the system CallLog (though they contain the same calls).
/// Filter chips (All/Missed/Incoming/Outgoing) match the filter row Google's
/// own Phone app shows above its call log.
class CallLogScreen extends ConsumerStatefulWidget {
  const CallLogScreen({super.key});

  @override
  ConsumerState<CallLogScreen> createState() => _CallLogScreenState();
}

class _CallLogScreenState extends ConsumerState<CallLogScreen> {
  List<CallRecord> _records = [];
  bool _loading = true;
  _LogFilter _filter = _LogFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await DialerCallLogRepository.instance.getAll();
    if (mounted) setState(() { _records = records; _loading = false; });
  }

  List<CallRecord> get _filtered => switch (_filter) {
        _LogFilter.all => _records,
        _LogFilter.missed => _records.where((r) => r.direction == CallDirection.missed).toList(),
        _LogFilter.incoming => _records.where((r) => r.direction == CallDirection.incoming).toList(),
        _LogFilter.outgoing => _records.where((r) => r.direction == CallDirection.outgoing).toList(),
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dateFormat = DateFormat('MMM d, h:mm a');
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recents'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in _LogFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_filterLabel(f)),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: kBrandColor.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: _filter == f ? kBrandColor : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: _filter == f ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(color: _filter == f ? kBrandColor : Theme.of(context).colorScheme.outlineVariant),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: filtered.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: 320,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call_outlined, size: 64,
                              color: Theme.of(context).colorScheme.outlineVariant),
                          const SizedBox(height: 16),
                          Text(
                            _records.isEmpty ? 'No calls yet' : 'No ${_filterLabel(_filter).toLowerCase()} calls',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final record = filtered[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _directionColor(record.direction).withValues(alpha: 0.12),
                      child: Icon(
                        _directionIcon(record.direction),
                        color: _directionColor(record.direction),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      record.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${dateFormat.format(record.startedAt)}  ·  ${record.durationLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.call_outlined, size: 22),
                      color: kBrandColor,
                      tooltip: 'Call back',
                      onPressed: () => ref
                          .read(dialerProvider.notifier)
                          .placeCall(record.phoneNumber),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _filterLabel(_LogFilter f) => switch (f) {
        _LogFilter.all => 'All',
        _LogFilter.missed => 'Missed',
        _LogFilter.incoming => 'Incoming',
        _LogFilter.outgoing => 'Outgoing',
      };

  IconData _directionIcon(CallDirection d) => switch (d) {
        CallDirection.incoming => Icons.call_received,
        CallDirection.outgoing => Icons.call_made,
        CallDirection.missed => Icons.call_missed,
      };

  Color _directionColor(CallDirection d) => switch (d) {
        CallDirection.incoming => kBrandColor,
        CallDirection.outgoing => Colors.blue.shade600,
        CallDirection.missed => Colors.red.shade600,
      };
}
