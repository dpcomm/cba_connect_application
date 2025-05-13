import 'package:cba_connect_application/core/custom_exception.dart';
import 'package:dio/dio.dart';

import '../models/auth_response.dart';
import '../../core/network.dart';

// Request 추상클래스
abstract class AuthDataSource {
  Future<AuthResponse> login({
    required String userId,
    required String password,
    required bool autoLogin,
  });
}

class AuthDataSourceImpl implements AuthDataSource {
  @override
  Future<AuthResponse> login({
    required String userId,
    required String password,
    required bool autoLogin,
  }) async {
    try {
    final response = await Network.dio.post(
      '/api/user/login',
      data: {
        'userId': userId,
        'password': password,
        'autoLogin': autoLogin,
      },
    );
    // API 요청 후 응답을 AuthResponse 객체로 변환하여 Repository에 전달
    return AuthResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
    } on DioException catch (e) {
      print('로그인 실패: $e');
      if (e.response != null && e.response!.statusCode == 401) {
        throw InvalidCredentialsException();
      }
      if (e.response != null) {
        final data = e.response!.data as Map<String, dynamic>;
        final msg = data['message'] as String? ?? e.message;
        throw UnknownException(msg!);
      }
      throw NetworkException();
    }
  }
}