import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/dialer_provider.dart';
import '../../providers/dialer_state.dart';
import '../widgets/keypad_button.dart';
import '../widgets/lead_match_chip.dart';
import 'in_call_screen.dart';
import 'incoming_call_screen.dart';

/// The main dialer tab — numeric keypad, digit display, and the green call
/// button. Automatically navigates to [InCallScreen] or [IncomingCallScreen]
/// when the dialer state transitions away from idle.
class DialerScreen extends ConsumerStatefulWidget {
  const DialerScreen({super.key});

  @override
  ConsumerState<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends ConsumerState<DialerScreen> {
  @override
  Widget build(BuildContext context) {
    final dialerState = ref.watch(dialerProvider);
    final notifier = ref.read(dialerProvider.notifier);

    // Navigate away when a call starts.
    ref.listen<DialerState>(dialerProvider, (_, next) {
      if (next is DialerDialing || next is DialerInCall) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InCallScreen()),
        );
      } else if (next is DialerIncoming) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const IncomingCallScreen()),
        );
      }
    });

    final digits = dialerState is DialerIdle ? dialerState.digits : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Dialer')),
      body: Column(
        children: [
          // ── Digit display ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    digits.isEmpty ? '' : digits,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (digits.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.backspace_outlined),
                    onPressed: notifier.backspace,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const LeadMatchChip(),
          const SizedBox(height: 16),
          // ── Keypad ──────────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _KeypadRow(digits: const ['1', '2', '3'], subs: const ['', 'ABC', 'DEF'], notifier: notifier),
                  _KeypadRow(digits: const ['4', '5', '6'], subs: const ['GHI', 'JKL', 'MNO'], notifier: notifier),
                  _KeypadRow(digits: const ['7', '8', '9'], subs: const ['PQRS', 'TUV', 'WXYZ'], notifier: notifier),
                  _KeypadRow(digits: const ['*', '0', '#'], subs: const ['', '+', ''], notifier: notifier),
                  const SizedBox(height: 24),
                  // Call button
                  CallActionButton(
                    icon: Icons.call,
                    color: kBrandColor,
                    onPressed: digits.isNotEmpty ? () => notifier.placeCall(digits) : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _KeypadRow extends StatelessWidget {
  const _KeypadRow({
    required this.digits,
    required this.subs,
    required this.notifier,
  });

  final List<String> digits;
  final List<String> subs;
  final DialerNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < digits.length; i++)
            KeypadButton(
              label: digits[i],
              sublabel: subs[i],
              onPressed: () => notifier.pressDigit(digits[i]),
              onLongPress: digits[i] == '0' ? () => notifier.pressDigit('+') : null,
            ),
        ],
      ),
    );
  }
}
