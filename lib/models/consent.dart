class Consent {
  final int userId;
  final String consentType;
  final bool value;
  final DateTime? consentedAt;

  Consent({
    required this.userId,
    required this.consentType,
    required this.value,
    this.consentedAt,
  });

  factory Consent.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('consent')
        ? json['consent'] as Map<String, dynamic>
        : json;

    return Consent(
      userId: data['userId'] as int,
      consentType: data['consentType'] as String,
      value: data['value'] as bool,
      consentedAt: data['consentedAt'] != null
          ? DateTime.parse(data['consentedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'consentType': consentType,
    'value': value,
    'consentedAt': consentedAt?.toIso8601String(),
  };
}
