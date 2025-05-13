class ErrorResponse {
  final String message;
  final dynamic err;

  ErrorResponse({
    required this.message,
    this.err,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      message: json['message'] as String,
      err: json['err'],
    );
  }
}