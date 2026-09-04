// Domain model for a single call record in the dialer's own call log.
// Kept simple and serialization-free intentionally — this list is ephemeral
// (in-memory + SharedPrefs) and never sent to the backend; the CRM sync path
// uses PendingCallEvent / CallLogDetails instead.

enum CallDirection { incoming, outgoing, missed }

class CallRecord {
  const CallRecord({
    required this.id,
    required this.phoneNumber,
    required this.direction,
    required this.startedAt,
    required this.durationSeconds,
    this.matchedLeadName,
    this.matchedOrgName,
  });

  final String id;
  final String phoneNumber;
  final CallDirection direction;
  final DateTime startedAt;
  final int durationSeconds;
  final String? matchedLeadName;
  final String? matchedOrgName;

  String get displayName => matchedLeadName ?? phoneNumber;

  String get durationLabel {
    if (durationSeconds <= 0) return '—';
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        'direction': direction.name,
        'startedAtMillis': startedAt.millisecondsSinceEpoch,
        'durationSeconds': durationSeconds,
        if (matchedLeadName != null) 'matchedLeadName': matchedLeadName,
        if (matchedOrgName != null) 'matchedOrgName': matchedOrgName,
      };

  factory CallRecord.fromJson(Map<String, dynamic> json) => CallRecord(
        id: json['id'] as String,
        phoneNumber: json['phoneNumber'] as String,
        direction: CallDirection.values.firstWhere(
          (d) => d.name == json['direction'],
          orElse: () => CallDirection.outgoing,
        ),
        startedAt: DateTime.fromMillisecondsSinceEpoch(json['startedAtMillis'] as int),
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        matchedLeadName: json['matchedLeadName'] as String?,
        matchedOrgName: json['matchedOrgName'] as String?,
      );
}
