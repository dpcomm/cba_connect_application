import '../dtos/auth_response.dart';
import '../../core/network.dart';

class AuthRepository {
  Future<AuthResponse> login(String username, String password, bool autoLogin) async {
    final response = await Network.dio.post(
      '/user/login',
      data: {'username': username, 'password': password, 'autoLogin': autoLogin},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
