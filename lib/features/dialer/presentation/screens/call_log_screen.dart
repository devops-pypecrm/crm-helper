import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/dialer_call_log_repository.dart';
import '../../domain/call_record.dart';
import '../../providers/dialer_provider.dart';

/// Recent-calls list — calls placed or received through this app's dialer.
/// Separate from the system CallLog (though they contain the same calls).
class CallLogScreen extends ConsumerStatefulWidget {
  const CallLogScreen({super.key});

  @override
  ConsumerState<CallLogScreen> createState() => _CallLogScreenState();
}

class _CallLogScreenState extends ConsumerState<CallLogScreen> {
  List<CallRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await DialerCallLogRepository.instance.getAll();
    if (mounted) setState(() { _records = records; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_records.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recent calls')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_outlined, size: 64,
                  color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text('No calls yet',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('MMM d, h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Recent calls')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          itemCount: _records.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final record = _records[index];
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
              onTap: () {},
            );
          },
        ),
      ),
    );
  }

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
