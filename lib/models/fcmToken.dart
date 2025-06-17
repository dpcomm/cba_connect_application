class FcmToken {
  final int userId;
  final String token;

  FcmToken({
    required this.userId,
    required this.token,
  });

  factory FcmToken.fromJson(Map<String, dynamic> json) {
    return FcmToken(
      userId: (json['userId'] as num).toInt(),
      token: json['token'] as String,
    );
  }
}