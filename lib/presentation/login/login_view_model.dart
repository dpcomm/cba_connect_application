import 'package:cba_connect_application/core/secure_storage.dart';
import 'package:cba_connect_application/datasources/auth_data_source.dart';
import 'package:cba_connect_application/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/core/socket/socket_manager.dart';

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

  Future<void> login(String userId, String password, bool autoLogin) async {
    // 로그인 상태 값
    state = LoginState(status: LoginStatus.loading);
    try {
      final response = await _repository.login(
        userId: userId,
        password: password,
        autoLogin: autoLogin,
      );

      await SecureStorage.write(key: 'access-token', value: response.accessToken);
      if (autoLogin) await SecureStorage.write(key: 'refresh-token', value: response.refreshToken!);

      final socketManager = SocketManager();
      socketManager.setSocket(response.accessToken);
      socketManager.connect();

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

// DataSource 프로바이더
final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  return AuthDataSourceImpl();
});

// Repository 프로바이더
// 단일 책임 원칙을 따르므로, AuthDataSource는 API 호출 -> Model 변환만을 담당.
// AuthRepository는 AuthDataSource를 사용해 데이터를 뷰모델에 전달.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.read(authDataSourceProvider);
  return AuthRepository(dataSource: dataSource);
});

// ViewModel 프로바이더
// ViewModel에 authRepository를 주입.
final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>(
  (ref) {
    final repo = ref.read(authRepositoryProvider);
    return LoginViewModel(repo);
  },
);
