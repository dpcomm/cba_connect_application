import 'user.dart';

class AuthResponse {
  final String message;
  final String accessToken;
  final String? refreshToken;  // 자동 로그인 시 리프레시 토큰이 들어오지 않을 수 있음.
  final User user;

  AuthResponse({
    required this.message,
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
  @override
  String toString() {
    return 'AuthResponse(message: $message, accessToken: $accessToken, refreshToken: $refreshToken, user: ${user.name})';
  }
}
