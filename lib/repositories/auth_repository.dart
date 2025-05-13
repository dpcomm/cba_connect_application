// Repository는 DataSource를 사용하여 데이터를 가져오고, ViewModel에 전달하는 역할을 함
import 'package:cba_connect_application/core/custom_exception.dart';
import 'package:cba_connect_application/datasources/auth_data_source.dart';
import 'package:cba_connect_application/models/auth_response.dart';

class AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepository({required AuthDataSource dataSource})
    : _dataSource = dataSource;

  // 로그인 API 요청 시 AuthResponse의 객체를 반환하므로 미래 타입 지정
  Future<AuthResponse> login({
    required String userId,
    required String password,
    required bool autoLogin,
  }) async {
    try {
      return await _dataSource.login(
        userId: userId,
        password: password,
        autoLogin: autoLogin,
      );
    }
    // 예외 처리
    // 레포지토리에서 예외는 데이터소스에서 반환한 예외 메시지 혹은 그 부모의 커스텀익셉션의 메시지를 전달한다.
    // 즉 커스텀익셉션에서 발생한 메시지만 동일하게 전달하는 역할. 다른 메시지를 전하고 싶으면 데이타소스 혹은 커스텀익셉션에서 수정해야함.
    on InvalidCredentialsException catch (e) {
      print('로그인 실패: $e');
      return Future.error(e.message);
    } on NetworkException catch (e) {
      print('네트워크 오류: $e');
      return Future.error(e.message);
    } on UnknownException catch (e) {
      print('알 수 없는 오류: $e');
      return Future.error(e.message);
    } catch (e) {
      print('로그인 실패: $e');
      return Future.error(e.toString());
    }
  }
}
