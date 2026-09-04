import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/dialer_provider.dart';
import '../../providers/dialer_state.dart';
import '../widgets/keypad_button.dart';

/// Full-screen incoming-call UI displayed over the lock screen when the app
/// is the default dialer and a call arrives. Shows the caller's CRM identity
/// (or raw number), with large answer (green) and decline (red) buttons.
///
/// Phase 1: this screen can be reached programmatically for testing.
/// Phase 2: shown automatically via MethodChannel event from PypeConnectionService.
class IncomingCallScreen extends ConsumerWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dialerState = ref.watch(dialerProvider);
    final notifier = ref.read(dialerProvider.notifier);

    // Pop if state transitions away from incoming (answered or declined).
    ref.listen<DialerState>(dialerProvider, (_, next) {
      if (next is! DialerIncoming && context.mounted) {
        Navigator.of(context).maybePop();
      }
    });

    final number = dialerState is DialerIncoming ? dialerState.number : '';
    final leadName = dialerState is DialerIncoming ? dialerState.leadMatch?.name : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1F0F),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            // Incoming ring animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              onEnd: () {},
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kBrandColor.withValues(alpha: 0.15),
                  border: Border.all(color: kBrandColor.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.person, size: 48, color: Colors.white60),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Incoming Call',
              style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            if (leadName != null) ...[
              Text(
                leadName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              number,
              style: TextStyle(
                color: Colors.white.withValues(alpha: leadName != null ? 0.55 : 1.0),
                fontSize: leadName != null ? 16 : 28,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            // ── Answer / Decline ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      CallActionButton(
                        icon: Icons.call_end,
                        color: Colors.red.shade700,
                        size: 80,
                        onPressed: notifier.declineCall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      CallActionButton(
                        icon: Icons.call,
                        color: kBrandColor,
                        size: 80,
                        onPressed: notifier.answerCall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Answer',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
