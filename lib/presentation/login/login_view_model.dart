import 'package:flutter_application_1/core/secure_storage.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 로그인 상태값 enum(로그인 성공 여부를 따지기 위함으로, 필요할 경우에만 선언)
enum LoginStatus { initial, loading, success, error }

// 로그인 상태 관리 요소 클래스
class LoginState {
  final LoginStatus status;
  final String? message;
  LoginState({this.status = LoginStatus.initial, this.message});
}

class LoginViewModel extends StateNotifier<LoginState> {
  final AuthRepository _repository;

  // 자식 클래스에서 생성자 호출 전 부모 클래스의 생성자 호출
  LoginViewModel(this._repository): super(LoginState());

  Future<void> login(String username, String password, bool autoLogin) async {
    // 로그인 상태 값
    state = LoginState(status: LoginStatus.loading);
    try {
      final response = await _repository.login(username, password, autoLogin);
      await SecureStorage.write(key: 'access-token', value: response.accessToken);
      await SecureStorage.write(key: 'refresh-token', value: response.refreshToken);
      // 성공했으므로 로그인 전역변수를 성공으로 변경.
      state = LoginState(status: LoginStatus.success);
    } catch (error) {
      // 실패 결과를 로그인 전역변수에 저장
      state = LoginState(
        status: LoginStatus.error,
        message: error.toString(),
      );
    }
  }
}

// AuthRepository riverpod에 등록
final authRepositoryProvider = Provider((_) => AuthRepository());

// LoginViewModel riverpod에 등록
final loginViewModelProvider =
  StateNotifierProvider<LoginViewModel, LoginState>(
    (ref) => LoginViewModel(ref.read(authRepositoryProvider)),
  );