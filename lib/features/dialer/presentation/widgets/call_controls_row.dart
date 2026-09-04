import 'package:flutter/material.dart';

import '../../providers/dialer_provider.dart';
import '../../providers/dialer_state.dart';
import '../../../../../core/theme/app_theme.dart';

/// Mute / Speaker / Hold control strip displayed during an active call.
class CallControlsRow extends StatelessWidget {
  const CallControlsRow({super.key, required this.state, required this.notifier});

  final DialerInCall state;
  final DialerNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: state.muted ? Icons.mic_off : Icons.mic,
          label: state.muted ? 'Unmute' : 'Mute',
          active: state.muted,
          onTap: notifier.toggleMute,
        ),
        _ControlButton(
          icon: state.speakerOn ? Icons.volume_up : Icons.volume_down,
          label: 'Speaker',
          active: state.speakerOn,
          onTap: notifier.toggleSpeaker,
        ),
        _ControlButton(
          icon: state.onHold ? Icons.play_arrow : Icons.pause,
          label: state.onHold ? 'Resume' : 'Hold',
          active: state.onHold,
          onTap: notifier.toggleHold,
        ),
        _ControlButton(
          icon: Icons.dialpad,
          label: 'Keypad',
          active: false,
          onTap: () {}, // Phase 2: show DTMF overlay
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: active
                  ? kBrandColor.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: active ? kBrandColor : Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
