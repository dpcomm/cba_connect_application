class RefreshFcmTokenDto {
  final int userId;
  final String oldToken;
  final String newToken;

  RefreshFcmTokenDto({
    required this.userId,
    required this.oldToken,
    required this.newToken,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'oldToken': oldToken,
    'newToken': newToken,
  };
}