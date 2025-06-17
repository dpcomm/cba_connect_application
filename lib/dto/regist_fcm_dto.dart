class RegistFcmDto {
  final int userId;
  final String token;

  RegistFcmDto({
    required this.userId,
    required this.token,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'token': token,
  };
}