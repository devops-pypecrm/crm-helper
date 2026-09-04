/// A CRM lead matched to a phone number. Used while the user types in the
/// dialer screen (real-time) and during call display (in-call / call log).
class LeadMatch {
  const LeadMatch({
    required this.id,
    required this.name,
    required this.orgName,
    required this.phoneNumber,
  });

  final String id;
  final String name;
  final String orgName;
  final String phoneNumber;

  factory LeadMatch.fromJson(Map<String, dynamic> json) => LeadMatch(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        orgName: json['orgName'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
      );
}
