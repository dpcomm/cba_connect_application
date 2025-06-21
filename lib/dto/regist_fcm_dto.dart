class RegistFcmDto {
  final int userId;
  final String token;
  final String platform;

  RegistFcmDto({
    required this.userId,
    required this.token,
    required this.platform
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'token': token,
    'platform': platform,
  };
}