import 'package:call_recording_engine/call_recording_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/domain/user_session.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../updates/presentation/screens/updates_screen.dart';
import '../../../updates/presentation/widgets/update_banner.dart';
import '../../../updates/providers/app_update_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/engine_provider.dart';
import '../../providers/status_provider.dart';

class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).valueOrNull;
    final statusAsync = ref.watch(engineStatusControllerProvider);

    final updateAvailable = ref.watch(availableUpdateProvider).valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PypeCRM Helper'),
        actions: [
          IconButton(
            tooltip: 'Updates',
            icon: Badge(
              isLabelVisible: updateAvailable,
              smallSize: 8,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.system_update_outlined),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UpdatesScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(engineStatusControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const UpdateBanner(),
            if (session != null) _SignedInCard(session: session),
            const SizedBox(height: 16),
            statusAsync.when(
              data: (status) => _StatusCard(status: status),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Could not read engine status: $error'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Permissions & battery setup'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OnboardingScreen(fromStatusScreen: true)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.session});

  final UserSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kBrandColor.withValues(alpha: 0.15),
          foregroundColor: kBrandColor,
          child: const Icon(Icons.person),
        ),
        title: Text('${session.firstName} ${session.lastName}'),
        subtitle: Text('${session.organisation.name} · ${session.email}'),
      ),
    );
  }
}

class _StatusCard extends ConsumerStatefulWidget {
  const _StatusCard({required this.status});

  final EngineStatus status;

  @override
  ConsumerState<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends ConsumerState<_StatusCard> with SingleTickerProviderStateMixin {
  late final AnimationController _syncIconController;
  bool _isSyncing = false;
  bool _isDefaultDialer = false;

  @override
  void initState() {
    super.initState();
    _syncIconController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _loadDialerStatus();
  }

  Future<void> _loadDialerStatus() async {
    try {
      final result = await ref.read(callRecordingEngineProvider).isDefaultDialer();
      if (mounted) setState(() => _isDefaultDialer = result);
    } catch (_) {}
  }

  @override
  void dispose() {
    _syncIconController.dispose();
    super.dispose();
  }

  Future<void> _handleSyncNow() async {
    setState(() => _isSyncing = true);
    _syncIconController.repeat();
    try {
      final result = await ref.read(engineStatusControllerProvider.notifier).syncCallLogsNow();
      if (!mounted) return;

      final audioBefore = result.before.tier0SuccessCount +
          result.before.tier1SuccessCount +
          result.before.tier2SuccessCount +
          result.before.tier3SuccessCount;
      final audioAfter = result.after.tier0SuccessCount +
          result.after.tier1SuccessCount +
          result.after.tier2SuccessCount +
          result.after.tier3SuccessCount;
      final newRecordings = audioAfter - audioBefore;
      final newCallLogs = result.after.tier4SuccessCount - result.before.tier4SuccessCount;

      final String message;
      if (newRecordings <= 0 && newCallLogs <= 0) {
        message = 'Sync complete — no new calls found since last sync.';
      } else {
        final parts = <String>[
          if (newRecordings > 0) '$newRecordings recording${newRecordings == 1 ? '' : 's'} recovered',
          if (newCallLogs > 0) '$newCallLogs call log${newCallLogs == 1 ? '' : 's'} synced',
        ];
        message = 'Sync complete — ${parts.join(', ')}.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: kBrandColor),
      );
    } finally {
      _syncIconController.stop();
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final dateFormat = DateFormat('MMM d, h:mm a');
    final permissionsAsync = ref.watch(enginePermissionsProvider);
    final callLogGranted = permissionsAsync.valueOrNull?[CallRecordingEngine.readCallLogPermission] ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Call monitoring', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: status.monitoringEnabled
                            ? kBrandColor.withValues(alpha: 0.15)
                            : Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.monitoringEnabled ? 'Active' : 'Off',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: status.monitoringEnabled
                              ? kBrandColor
                              : Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: status.monitoringEnabled,
                  onChanged: (enabled) =>
                      ref.read(engineStatusControllerProvider.notifier).toggleMonitoring(enabled),
                ),
              ],
            ),
            const Divider(),
            _StatRow(
              label: 'Last synced call',
              value: status.lastSyncedAt == null ? 'Never yet' : dateFormat.format(status.lastSyncedAt!),
            ),
            _StatRow(
              label: "Recordings found (phone's own recorder)",
              value: '${status.tier0SuccessCount}',
            ),
            _StatRow(
              label: 'Recordings captured by this app',
              value: '${status.tier1SuccessCount + status.tier2SuccessCount}',
            ),
            if (status.tier3SuccessCount > 0)
              _StatRow(
                label: 'Recordings captured (fallback method)',
                value: '${status.tier3SuccessCount}',
              ),
            _StatRow(
              label: 'Call logs synced (metadata only, no audio)',
              value: '${status.tier4SuccessCount}',
            ),
            _StatRow(
              label: 'Call log history access',
              value: callLogGranted ? 'Granted' : 'Not granted',
            ),
            _StatRow(
              label: 'Default dialer',
              value: _isDefaultDialer ? 'Active' : 'Inactive',
            ),
            _StatRow(
              label: 'WhatsApp replies logged',
              value: '${status.whatsAppSyncCount}',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: RotationTransition(
                  turns: _syncIconController,
                  child: const Icon(Icons.sync, size: 18),
                ),
                label: Text(_isSyncing ? 'Syncing…' : 'Sync call logs now'),
                onPressed: (!callLogGranted || _isSyncing) ? null : _handleSyncNow,
              ),
            ),
            if (!status.monitoringEnabled) ...[
              const SizedBox(height: 8),
              const Text(
                'Monitoring is off — no calls are being watched or synced to the CRM.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
