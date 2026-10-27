import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Shared press-scale + haptic behavior for [PrimaryButton]/[SecondaryButton]
/// — pulled out so both pill buttons animate identically instead of each
/// re-implementing the same `GestureDetector` wrapper.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Pill-shaped filled button (brand green) with press-scale + haptic
/// feedback — the app-wide replacement for bare `FilledButton`.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = _PressScale(
      onPressed: loading ? null : onPressed,
      child: Container(
        height: kButtonHeight,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: (loading || onPressed == null) ? kBrandColor.withValues(alpha: 0.4) : kBrandColor,
          borderRadius: BorderRadius.circular(kButtonRadius),
          boxShadow: (loading || onPressed == null)
              ? null
              : [
                  BoxShadow(
                    color: kBrandColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: -6,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 10)],
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// Pill-shaped outlined button — the app-wide replacement for bare
/// `OutlinedButton`/`TextButton` secondary actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = _PressScale(
      onPressed: onPressed,
      child: Container(
        height: kButtonHeight,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(kButtonRadius),
          border: Border.all(color: kBrandColor.withValues(alpha: onPressed == null ? 0.3 : 1), width: 1.4),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: kBrandColor.withValues(alpha: onPressed == null ? 0.4 : 1), size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: TextStyle(
                color: kBrandColor.withValues(alpha: onPressed == null ? 0.4 : 1),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}
