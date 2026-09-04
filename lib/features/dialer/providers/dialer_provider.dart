import 'package:call_recording_engine/call_recording_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/status/providers/engine_provider.dart';
import 'dialer_state.dart';

/// Owns the dialer's call lifecycle state. Call-state transitions come from
/// the Flutter UI (key presses, answer/decline/end buttons) — the Kotlin side
/// (PypeConnection) drives the *recording* path independently; this provider
/// only drives the Flutter UI state machine.
///
/// NOTE: Phase 1 ships with this provider available but not yet wired to
/// any real incoming-call push. Phase 2 will connect it to a MethodChannel
/// event from PypeConnectionService for incoming-call UI.
class DialerNotifier extends StateNotifier<DialerState> {
  DialerNotifier(this._engine) : super(const DialerIdle());

  final CallRecordingEngine _engine;

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
      // Ensure PhoneAccount is registered before placing the call.
      await _engine.registerPhoneAccount();
      await _engine.placeCall(number);
      // PypeConnection will transition state to ACTIVE via the incoming
      // MethodChannel event in Phase 2. For now, we move to DialerInCall
      // optimistically after a short delay so the UI doesn't get stuck.
      await Future.delayed(const Duration(seconds: 2));
      if (state is DialerDialing) {
        state = DialerInCall(
          number: number,
          startedAt: DateTime.now(),
          isOutgoing: true,
        );
      }
    } catch (e) {
      state = const DialerIdle();
    }
  }

  // ── In-call controls ──────────────────────────────────────────────────────

  void toggleMute() {
    if (state is DialerInCall) {
      final s = state as DialerInCall;
      state = s.copyWith(muted: !s.muted);
    }
  }

  void toggleSpeaker() {
    if (state is DialerInCall) {
      final s = state as DialerInCall;
      state = s.copyWith(speakerOn: !s.speakerOn);
    }
  }

  void toggleHold() {
    if (state is DialerInCall) {
      final s = state as DialerInCall;
      state = s.copyWith(onHold: !s.onHold);
    }
  }

  void endCall() {
    // The actual teardown goes via PypeConnection.onDisconnect() on the
    // Kotlin side; here we just return the UI to idle.
    state = const DialerIdle();
  }

  // ── Incoming call (Phase 2: triggered by MethodChannel event) ────────────

  void onIncomingCall(String number) {
    state = DialerIncoming(number: number);
  }

  void answerCall() {
    if (state is DialerIncoming) {
      final inc = state as DialerIncoming;
      state = DialerInCall(
        number: inc.number,
        startedAt: DateTime.now(),
        isOutgoing: false,
        leadMatch: inc.leadMatch,
      );
    }
  }

  void declineCall() {
    state = const DialerIdle();
  }
}

final dialerProvider = StateNotifierProvider<DialerNotifier, DialerState>(
  (ref) => DialerNotifier(ref.watch(callRecordingEngineProvider)),
);
