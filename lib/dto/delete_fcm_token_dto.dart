class DeleteFcmTokenDto {
  final String token;

  DeleteFcmTokenDto({
    required this.token,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
  };
}