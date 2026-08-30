import 'package:call_recording_engine/call_recording_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/domain/user_session.dart';
import '../../../auth/providers/session_provider.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../poc/presentation/screens/role_settings_screen.dart';
import '../../providers/status_provider.dart';

class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).valueOrNull;
    final statusAsync = ref.watch(engineStatusControllerProvider);

    return Scaffold(
      appBar: AppBar(
        // Long-press reaches the Milestone 1 POC (conference-recording
        // experiment) — deliberately hidden, this is a debug surface, not
        // part of the shipped Phase 1-5 flow.
        title: GestureDetector(
          onLongPress: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RoleSettingsScreen()),
          ),
          child: const Text('Pype Call Recorder'),
        ),
        actions: [
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
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text('${session.firstName} ${session.lastName}'),
        subtitle: Text('${session.organisation.name} · ${session.email}'),
      ),
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.status});

  final EngineStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Call monitoring', style: TextStyle(fontWeight: FontWeight.bold)),
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
