import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// A single button on the numeric keypad (0-9, *, #) or the backspace key.
class KeypadButton extends StatelessWidget {
  const KeypadButton({
    super.key,
    required this.label,
    this.sublabel,
    this.onPressed,
    this.onLongPress,
    this.icon,
    this.size = 72,
  });

  final String label;
  final String? sublabel;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          onLongPress: onLongPress,
          splashColor: kBrandColor.withValues(alpha: 0.15),
          highlightColor: kBrandColor.withValues(alpha: 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(icon, size: 28, color: Theme.of(context).colorScheme.onSurface)
              else
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              if (sublabel != null && sublabel!.isNotEmpty)
                Text(
                  sublabel!,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The big green call-action button (place or end call).
class CallActionButton extends StatelessWidget {
  const CallActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 72,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.46),
      ),
    );
  }
}
