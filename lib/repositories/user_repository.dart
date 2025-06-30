import 'package:cba_connect_application/core/custom_exception.dart';
import 'package:cba_connect_application/datasources/user_data_source.dart';
import 'package:cba_connect_application/dto/update_user_dto.dart';

abstract class UserRepository {
  Future<void> updateUserName(UpdateUserNamelDto updateUserNamelDto);
  Future<void> updateUserPhone(UpdateUserPhoneDto updateUserPhoneDto);
  Future<void> deleteUser(int userId);
}

class UserRepositoryImpl implements UserRepository {
  final UserDataSource _dataSource;
  UserRepositoryImpl(this._dataSource);

  @override
  Future<void> updateUserName(UpdateUserNamelDto dto) async {
    try {
      await _dataSource.updateUserName(dto);
    } on CustomException {
      rethrow;
    } catch (e) {
      throw UnknownException('사용자 이름 업데이트 중 예기치 않은 오류: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUserPhone(UpdateUserPhoneDto dto) async {
    try {
      await _dataSource.updateUserPhone(dto);
    } on CustomException {
      rethrow;
    } catch (e) {
      throw UnknownException('사용자 전화번호 업데이트 중 예기치 않은 오류: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteUser(int userId) async {
    try {
      await _dataSource.deleteUser(userId);
    } on CustomException {
      rethrow;
    } catch (e) {
      throw UnknownException('계정 삭제 중 예기치 않은 오류: ${e.toString()}');
    }
  }
}