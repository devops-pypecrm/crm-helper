import 'dart:async';
import 'package:flutter/material.dart';

/// Displays elapsed call time since [startedAt], ticking every second.
class CallTimer extends StatefulWidget {
  const CallTimer({super.key, required this.startedAt, this.style});

  final DateTime startedAt;
  final TextStyle? style;

  @override
  State<CallTimer> createState() => _CallTimerState();
}

class _CallTimerState extends State<CallTimer> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startedAt);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed = DateTime.now().difference(widget.startedAt));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final label = h > 0 ? '$h:$m:$s' : '$m:$s';
    return Text(
      label,
      style: widget.style ??
          const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
    );
  }
}
