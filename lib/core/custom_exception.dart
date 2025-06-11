abstract class CustomException implements Exception {
  String get message;
}

// 아이디, 비밀번호 틀렸을 경우
class InvalidCredentialsException implements CustomException {
  @override
  final String message;
  InvalidCredentialsException([this.message = 'Invalid credentials.']);
}

// 사용자가 존재하지 않을 경우
class UserNotFoundException implements CustomException {
  @override
  final String message;
  UserNotFoundException([this.message = 'User not found.']);
}

// 네트워크 에러
class NetworkException implements CustomException {
  @override
  final String message;
  NetworkException([this.message = 'Failed to connect to the network.']);
}

// 그 외 알 수 없는 에러
class UnknownException implements CustomException {
  @override
  final String message;
  UnknownException([this.message = 'Unknown error occurred.']);
}

class UnauthorizedApiKeyException implements CustomException {
  @override
  final String message;
  UnauthorizedApiKeyException([this.message = 'Unauthorized Api Key']);
}