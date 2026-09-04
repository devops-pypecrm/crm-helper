import 'dart:async';

import 'package:call_recording_engine/call_recording_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/status/providers/engine_provider.dart';
import 'dialer_state.dart';

/// Owns the dialer's call lifecycle state. ALL in-call state transitions
/// (dialing → active → disconnected, or an incoming call ringing) come
/// exclusively from [CallRecordingEngine.callEvents] — the real Android
/// Call object's state, pushed from PypeInCallService (native). This
/// provider does not simulate or guess at call state; an earlier version
/// did (a hardcoded delay before showing "in call" regardless of whether a
/// real call ever connected), which is exactly why the in-call screen used
/// to show a running timer with no call actually happening.
///
/// Placing a call only WORKS the way this screen expects (i.e. produces
/// events this provider can see) once the app holds the default-dialer
/// role — see [PypeInCallService]'s doc comment. If it doesn't,
/// TelecomManager still places the call, but Android delivers it to
/// whichever app IS the default dialer (usually the stock Phone app), so
/// this provider has no way to know what happened — [_dialTimeout] bounds
/// how long we wait in [DialerDialing] before giving up and returning to
/// idle, rather than getting stuck forever.
class DialerNotifier extends StateNotifier<DialerState> {
  DialerNotifier(this._engine) : super(const DialerIdle()) {
    _eventsSub = _engine.callEvents.listen(_onCallEvent, onError: (_) {});
  }

  final CallRecordingEngine _engine;
  late final StreamSubscription<Map<String, Object?>> _eventsSub;
  Timer? _dialTimeout;

  @override
  void dispose() {
    _eventsSub.cancel();
    _dialTimeout?.cancel();
    super.dispose();
  }

  void _onCallEvent(Map<String, Object?> event) {
    final callState = event['state'] as String?;
    final number = event['number'] as String? ?? '';
    final isOutgoing = event['isOutgoing'] as bool? ?? false;

    switch (callState) {
      case 'RINGING':
        if (!isOutgoing) {
          _dialTimeout?.cancel();
          state = DialerIncoming(number: number);
        }
      case 'DIALING':
      case 'CONNECTING':
        _dialTimeout?.cancel();
        state = DialerDialing(number: number);
      case 'ACTIVE':
        _dialTimeout?.cancel();
        final current = state;
        state = DialerInCall(
          number: number,
          startedAt: DateTime.now(),
          isOutgoing: isOutgoing,
          leadMatch: current is DialerIncoming
              ? current.leadMatch
              : (current is DialerDialing ? current.leadMatch : null),
        );
      case 'DISCONNECTED':
      case 'DISCONNECTING':
        _dialTimeout?.cancel();
        state = const DialerIdle();
    }
  }

  // ── Keypad ────────────────────────────────────────────────────────────────

  void pressDigit(String digit) {
    if (state is DialerIdle) {
      final current = (state as DialerIdle).digits;
      state = DialerIdle(digits: current + digit);
    }
  }

  void backspace() {
    if (state is DialerIdle) {
      final current = (state as DialerIdle).digits;
      if (current.isNotEmpty) {
        state = DialerIdle(digits: current.substring(0, current.length - 1));
      }
    }
  }

  void clearDigits() {
    state = const DialerIdle();
  }

  // ── Outgoing call ─────────────────────────────────────────────────────────

  Future<void> placeCall(String number) async {
    if (number.isEmpty) return;
    state = DialerDialing(number: number);
    try {
      await _engine.placeCall(number);
    } catch (e) {
      state = const DialerIdle();
      return;
    }
    // Bounds how long we wait for a real callEvents update (see class doc
    // comment) — most likely to fire if this app isn't the default dialer,
    // so the call was handed off to a different app entirely.
    _dialTimeout?.cancel();
    _dialTimeout = Timer(const Duration(seconds: 20), () {
      if (state is DialerDialing) state = const DialerIdle();
    });
  }

  // ── In-call controls — all proxy to the real Call object natively ────────

  void toggleMute() {
    if (state is DialerInCall) {
      final s = state as DialerInCall;
      final next = !s.muted;
      _engine.setCallMuted(next);
      state = s.copyWith(muted: next);
    }
  }

  void toggleSpeaker() {
    if (state is DialerInCall) {
      final s = state as DialerInCall;
      final next = !s.speakerOn;
      _engine.setCallSpeakerOn(next);
      state = s.copyWith(speakerOn: next);
    }
  }

  void toggleHold() {
    if (state is DialerInCall) {
      final s = state as DialerInCall;
      final next = !s.onHold;
      _engine.setCallHold(next);
      state = s.copyWith(onHold: next);
    }
  }

  void endCall() {
    _engine.endCall();
    // Actual teardown is confirmed by the DISCONNECTED event above; this
    // just reflects the user's action immediately so the button feels
    // responsive.
    state = const DialerIdle();
  }

  // ── Incoming call ─────────────────────────────────────────────────────────

  void answerCall() => _engine.answerCall();

  void declineCall() {
    _engine.rejectCall();
    state = const DialerIdle();
  }
}

final dialerProvider = StateNotifierProvider<DialerNotifier, DialerState>(
  (ref) => DialerNotifier(ref.watch(callRecordingEngineProvider)),
);
