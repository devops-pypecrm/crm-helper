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
///
/// Sizes itself with [LayoutBuilder] rather than fixed dimensions: this tab
/// lives inside the app's bottom-nav shell (AppBar + NavigationBar both eat
/// into available height), and a fixed keypad size that was fine on one
/// screen overflowed on a shorter/lower-density one — the exact "off
/// screen" glitch this replaces.
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Reserve space for everything that isn't a keypad row, then
            // divide what's left across the 4 rows + call button so the
            // whole keypad always fits — matching how Google's Phone app
            // dialpad scales to fill the screen without ever scrolling.
            const displayHeight = 72.0;
            const chipHeight = 40.0;
            const callButtonBlock = 96.0; // button + surrounding spacing
            const rows = 4;

            final remaining = constraints.maxHeight - displayHeight - chipHeight - callButtonBlock;
            final rowHeight = (remaining / rows).clamp(56.0, 84.0);
            final buttonSize = (rowHeight - 8).clamp(52.0, 72.0);

            return Column(
              children: [
                // ── Digit display ───────────────────────────────────────
                SizedBox(
                  height: displayHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              digits,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 3,
                              ),
                              maxLines: 1,
                            ),
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
                ),
                SizedBox(height: chipHeight, child: const Center(child: LeadMatchChip())),
                // ── Keypad ──────────────────────────────────────────────
                for (final row in const [
                  [
                    ['1', ''],
                    ['2', 'ABC'],
                    ['3', 'DEF'],
                  ],
                  [
                    ['4', 'GHI'],
                    ['5', 'JKL'],
                    ['6', 'MNO'],
                  ],
                  [
                    ['7', 'PQRS'],
                    ['8', 'TUV'],
                    ['9', 'WXYZ'],
                  ],
                  [
                    ['*', ''],
                    ['0', '+'],
                    ['#', ''],
                  ],
                ])
                  SizedBox(
                    height: rowHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final key in row)
                          KeypadButton(
                            label: key[0],
                            sublabel: key[1],
                            size: buttonSize,
                            onPressed: () => notifier.pressDigit(key[0]),
                            onLongPress: key[0] == '0' ? () => notifier.pressDigit('+') : null,
                          ),
                      ],
                    ),
                  ),
                // ── Call button ─────────────────────────────────────────
                SizedBox(
                  height: callButtonBlock,
                  child: Center(
                    child: CallActionButton(
                      icon: Icons.call,
                      color: kBrandColor,
                      size: buttonSize,
                      onPressed: digits.isNotEmpty ? () => notifier.placeCall(digits) : null,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
