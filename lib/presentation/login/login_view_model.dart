import 'package:cba_connect_application/core/provider.dart';
import 'package:cba_connect_application/core/secure_storage.dart';
import 'package:cba_connect_application/datasources/auth_data_source.dart';
import 'package:cba_connect_application/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/core/socket_manager.dart';
import 'package:cba_connect_application/models/user.dart';
import 'package:cba_connect_application/firebaseService/fcm_service.dart';
import 'package:cba_connect_application/core/lifecycle_manager.dart';

// 로그인 상태값 enum(로그인 성공 여부를 따지기 위함으로, 필요할 경우에만 선언)
enum LoginStatus { initial, loading, success, error }

// 로그인 상태 관리 요소 클래스
class LoginState {
  final LoginStatus status;
  final String? message;

  // chat에서 사용할 User정보 위해 추가
  final User? user;

  LoginState({this.status = LoginStatus.initial, this.message, this.user});
}

class LoginViewModel extends StateNotifier<LoginState> {
  final Ref ref;
  final AuthRepository _repository;
  final FcmService _fcmService;
  final socketManager = SocketManager();


  // 자식 클래스에서 생성자 호출 전 부모 클래스의 생성자 호출
  LoginViewModel(this.ref, this._repository, this._fcmService) : super(LoginState());

  Future<void> login(String userId, String password, bool autoLogin) async {
    // 로그인 상태 값
    state = LoginState(status: LoginStatus.loading);
    try {
      final response = await _repository.login(
        userId: userId,
        password: password,
        autoLogin: autoLogin,
      );

      await SecureStorage.write(
        key: 'access-token',
        value: response.accessToken,
      );
      if (autoLogin) {
        await SecureStorage.write(
          key: 'refresh-token',
          value: response.refreshToken!,
        );
      } else {
        final lifecycleManager = ref.read(lifecycleManagerProvider(response.user.id));
        lifecycleManager.start();
      }

      _fcmService.setToken(response.user.id);

      socketManager.setSocket(response.accessToken);
      socketManager.connect();

      // 성공했으므로 로그인 전역변수를 성공으로 변경 + user 정보 상태에 포함
      state = LoginState(status: LoginStatus.success, user: response.user);

    } catch (error) {
      // 실패 결과를 로그인 전역변수에 저장
      state = LoginState(status: LoginStatus.error, message: error.toString());
    }
  }

  Future<void> refreshLogin() async {
    final accessToken = await SecureStorage.read(key: 'access-token');
    final refreshToken = await SecureStorage.read(key: 'refresh-token');

    if (accessToken == null || refreshToken == null) return;

    /* 이 곳에 로딩 스피너 출력해야함. */
    state = LoginState(status: LoginStatus.loading);
    try {
      final response = await _repository.refreshLogin(
        accessToken: accessToken,
        refreshToken: refreshToken
      );

      await SecureStorage.write(
        key: 'access-token',
        value: response.accessToken,
      );

      _fcmService.setToken(response.user.id);

      socketManager.setSocket(response.accessToken);
      socketManager.connect();


      /* 이 곳에 로딩 스피너 해제. */
      state = LoginState(status: LoginStatus.success, user: response.user);
    } catch (e) {
      /* 이 곳에 로딩 스피너 해제. */
      state = LoginState(status: LoginStatus.error, message: e.toString());
    }
  }

  void updateUserNameInState(String newName) {
    final currentUser = state.user;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(name: newName);
    state = LoginState(
      status: state.status,
      message: state.message,
      user: updatedUser,
    );
  }

  void updateUserPhoneInState(String newPhone) {
    final currentUser = state.user;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(name: newPhone);
    state = LoginState(
      status: state.status,
      message: state.message,
      user: updatedUser,
    );
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
    StateNotifierProvider<LoginViewModel, LoginState>((ref) {
      final repo = ref.read(authRepositoryProvider);
      final fcmService = ref.read(fcmServiceProvider);
      return LoginViewModel(ref, repo, fcmService);
    });
