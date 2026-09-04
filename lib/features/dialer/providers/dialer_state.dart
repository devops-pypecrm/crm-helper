import '../domain/lead_match.dart';

/// The dialer's top-level UI state machine.
/// Sealed union: exactly one variant is active at a time.
sealed class DialerState {
  const DialerState();
}

/// No call in progress — the keypad is visible.
class DialerIdle extends DialerState {
  const DialerIdle({this.digits = ''});
  final String digits;
}

/// Outgoing call is being dialed (Telecom DIALING state).
class DialerDialing extends DialerState {
  const DialerDialing({required this.number, this.leadMatch});
  final String number;
  final LeadMatch? leadMatch;
}

/// Call is active (audio flowing, Telecom ACTIVE state).
class DialerInCall extends DialerState {
  const DialerInCall({
    required this.number,
    required this.startedAt,
    required this.isOutgoing,
    this.leadMatch,
    this.muted = false,
    this.speakerOn = false,
    this.onHold = false,
  });
  final String number;
  final DateTime startedAt;
  final bool isOutgoing;
  final LeadMatch? leadMatch;
  final bool muted;
  final bool speakerOn;
  final bool onHold;

  DialerInCall copyWith({
    bool? muted,
    bool? speakerOn,
    bool? onHold,
  }) =>
      DialerInCall(
        number: number,
        startedAt: startedAt,
        isOutgoing: isOutgoing,
        leadMatch: leadMatch,
        muted: muted ?? this.muted,
        speakerOn: speakerOn ?? this.speakerOn,
        onHold: onHold ?? this.onHold,
      );
}

/// Incoming call ringing (Telecom RINGING state).
class DialerIncoming extends DialerState {
  const DialerIncoming({required this.number, this.leadMatch});
  final String number;
  final LeadMatch? leadMatch;
}
