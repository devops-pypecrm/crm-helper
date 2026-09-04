import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dialer_provider.dart';
import '../../providers/dialer_state.dart';
import '../widgets/call_controls_row.dart';
import '../widgets/call_timer.dart';
import '../widgets/keypad_button.dart';

/// Full-screen in-call UI shown while a call is dialing or active.
/// Displays the caller identity (CRM lead match or raw number), an elapsed-
/// call timer once active, mute/speaker/hold/end controls.
class InCallScreen extends ConsumerWidget {
  const InCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dialerState = ref.watch(dialerProvider);
    final notifier = ref.read(dialerProvider.notifier);

    // If state transitions back to idle (call ended on the Kotlin side),
    // pop this screen.
    ref.listen<DialerState>(dialerProvider, (_, next) {
      if (next is DialerIdle && context.mounted) {
        Navigator.of(context).maybePop();
      }
    });

    String number;
    String? leadName;
    DateTime? callStart;
    bool isActive;

    if (dialerState is DialerDialing) {
      number = dialerState.number;
      leadName = dialerState.leadMatch?.name;
      callStart = null;
      isActive = false;
    } else if (dialerState is DialerInCall) {
      number = dialerState.number;
      leadName = dialerState.leadMatch?.name;
      callStart = dialerState.startedAt;
      isActive = true;
    } else {
      number = '';
      leadName = null;
      callStart = null;
      isActive = false;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1C2B1C), // dark brand green
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            // ── Caller identity ─────────────────────────────────────────
            if (leadName != null)
              Text(
                leadName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              number,
              style: TextStyle(
                color: Colors.white.withValues(alpha: leadName != null ? 0.6 : 1.0),
                fontSize: leadName != null ? 16 : 28,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            // ── Call status / timer ─────────────────────────────────────
            if (isActive && callStart != null)
              CallTimer(
                startedAt: callStart,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              )
            else
              const Text(
                'Calling…',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            const Spacer(),
            // ── Controls (only when active) ─────────────────────────────
            if (isActive && dialerState is DialerInCall)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CallControlsRow(
                  state: dialerState,
                  notifier: notifier,
                ),
              ),
            const SizedBox(height: 40),
            // ── End call button ─────────────────────────────────────────
            CallActionButton(
              icon: Icons.call_end,
              color: Colors.red.shade600,
              size: 80,
              onPressed: () {
                notifier.endCall();
              },
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
