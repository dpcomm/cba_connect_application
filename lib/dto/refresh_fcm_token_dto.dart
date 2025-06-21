class RefreshFcmTokenDto {
  final int userId;
  final String oldToken;
  final String newToken;
  final String platform;

  RefreshFcmTokenDto({
    required this.userId,
    required this.oldToken,
    required this.newToken,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'oldToken': oldToken,
    'newToken': newToken,
    'platform': platform,
  };
}