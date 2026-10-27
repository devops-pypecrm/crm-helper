import 'package:call_recording_engine/call_recording_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/domain/user_session.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../updates/presentation/screens/updates_screen.dart';
import '../../../updates/presentation/widgets/update_banner.dart';
import '../../../updates/providers/app_update_provider.dart';
import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_button.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/status_pill.dart';
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
              AppPageRoute(builder: (_) => const UpdatesScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              AppPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(engineStatusControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const UpdateBanner(),
            if (session != null)
              _SignedInCard(session: session).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08),
            const SizedBox(height: 16),
            statusAsync.when(
              data: (status) => _StatusCard(status: status)
                  .animate()
                  .fadeIn(delay: 60.ms, duration: 350.ms)
                  .slideY(begin: 0.08),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => PremiumCard(
                child: Text('Could not read engine status: $error'),
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
    return PremiumCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: kBrandColor.withValues(alpha: 0.15),
            foregroundColor: kBrandColor,
            child: const Icon(Icons.person),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.firstName} ${session.lastName}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.organisation.name} · ${session.email}',
                  style: const TextStyle(color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
  bool _isReverifying = false;

  @override
  void initState() {
    super.initState();
    _syncIconController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
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
      _showSyncResultSnackBar(result);
    } finally {
      _syncIconController.stop();
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  /// Rewinds today's sync watermark and re-checks every call from today
  /// against the phone's own Call Log — not just new ones. Slower than a
  /// plain sync (it re-reads the whole day), so it's a separate, explicit
  /// action rather than folded into "Sync call logs now" — see
  /// `EngineStatusController.reverifyToday`'s doc comment.
  Future<void> _handleReverifyToday() async {
    setState(() => _isReverifying = true);
    try {
      final result = await ref.read(engineStatusControllerProvider.notifier).reverifyToday();
      if (!mounted) return;
      _showSyncResultSnackBar(result);
    } finally {
      if (mounted) setState(() => _isReverifying = false);
    }
  }

  /// Both manual-sync buttons now await the real native outcome (see
  /// `ManualSyncResult`'s doc comment) instead of assuming success the
  /// moment the work was scheduled, so this reports what actually
  /// happened — including the cases that used to fail silently behind an
  /// always-green "synced" toast (missing permission, server rate limit,
  /// upload failure).
  void _showSyncResultSnackBar(ManualSyncResult result) {
    final String message;
    Color color = kBrandColor;
    switch (result.status) {
      case ManualSyncStatus.success:
        if (result.syncedCount <= 0 && result.reconciledCount <= 0) {
          message = 'All caught up — no new calls found.';
        } else {
          final parts = <String>[
            if (result.reconciledCount > 0)
              '${result.reconciledCount} call${result.reconciledCount == 1 ? '' : 's'} found',
            if (result.syncedCount > 0) '${result.syncedCount} synced',
            if (result.pendingCount > 0) '${result.pendingCount} still pending',
          ];
          message = 'Done — ${parts.join(', ')}.';
        }
      case ManualSyncStatus.rateLimited:
        message = 'Server is busy — will retry automatically in a few minutes.';
        color = Colors.orange;
      case ManualSyncStatus.failed:
        if (result.httpCode == 401 || result.httpCode == 403) {
          message = 'Session expired — please sign out and sign in again to resume syncing.';
        } else {
          final detail = result.httpCode?.toString() ?? result.errorMessage ?? 'network error';
          message = 'Sync failed ($detail) — ${result.pendingCount} call(s) still pending. Will retry automatically.';
        }
        color = Colors.red;
      case ManualSyncStatus.permissionMissing:
        message = 'Call Log permission is missing — grant it in Settings to sync calls.';
        color = Colors.red;
      case ManualSyncStatus.notSignedIn:
        message = 'Not signed in — sign in to the app first.';
        color = Colors.red;
      case ManualSyncStatus.noConnection:
        message = result.reconciledCount > 0
            ? '${result.reconciledCount} call(s) found and saved locally — connect to WiFi or mobile data to upload them.'
            : 'No internet connection — connect to WiFi or mobile data and try again.';
        color = Colors.orange;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final dateFormat = DateFormat('MMM d, h:mm a');
    final permissionsAsync = ref.watch(enginePermissionsProvider);
    final callLogGranted = permissionsAsync.valueOrNull?[CallRecordingEngine.readCallLogPermission] ?? false;
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Call monitoring', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 10),
                  StatusPill(
                    label: status.monitoringEnabled ? 'Active' : 'Off',
                    active: status.monitoringEnabled,
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
            label: 'Call logs synced (metadata only, no audio)',
            value: '${status.tier4SuccessCount}',
          ),
          _StatRow(
            label: 'Call log history access',
            value: callLogGranted ? 'Granted' : 'Not granted',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            icon: Icons.sync,
            label: _isSyncing ? 'Syncing…' : 'Sync call logs now',
            loading: _isSyncing,
            onPressed: (!callLogGranted || _isSyncing) ? null : _handleSyncNow,
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            icon: Icons.history,
            label: _isReverifying ? 'Re-checking…' : "Re-check today's calls",
            onPressed: (!callLogGranted || _isReverifying) ? null : _handleReverifyToday,
          ),
          if (!status.monitoringEnabled) ...[
            const SizedBox(height: 10),
            Text(
              'Monitoring is off — no calls are being watched or synced to the CRM.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54.withValues(alpha: 0.8)),
            ),
          ],
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
