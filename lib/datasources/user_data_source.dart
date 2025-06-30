import 'package:cba_connect_application/dto/update_user_dto.dart';
import 'package:dio/dio.dart';
import 'package:cba_connect_application/core/network.dart';
import 'package:cba_connect_application/core/custom_exception.dart';
import 'package:cba_connect_application/core/secure_storage.dart'; 

abstract class UserDataSource {
  Future<void> updateUserName(UpdateUserNamelDto dto);
  Future<void> updateUserPhone(UpdateUserPhoneDto dto);
  Future<void> deleteUser(int userId);
}

class UserDataSourceImpl implements UserDataSource {
  final Dio _dio = Network.dio;

  UserDataSourceImpl();

  @override
  Future<void> updateUserName(UpdateUserNamelDto dto) async {
    final String? accessToken = await SecureStorage.read(key: 'access-token');

    if (accessToken == null) {
      throw UnauthorizedApiKeyException('Access Token not found');
    }

    try {
      final resp = await _dio.post(
        '/api/user/update-name',
        data: dto.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'} ),
      );

    if (resp.statusCode != 200) {
      throw NetworkException('Failed to update name: ${resp.data}');
    }
    
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw UnknownException('Unexpected error: $e');
    }
  }

  @override
  Future<void> updateUserPhone(UpdateUserPhoneDto dto) async {
    final String? accessToken = await SecureStorage.read(key: 'access-token');

    if (accessToken == null) {
      throw UnauthorizedApiKeyException('Access Token not found');
    }

    try {
      final resp = await _dio.post(
        '/api/user/update-phone',
        data: dto.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'} ),
      );

    if (resp.statusCode != 200) {
      throw NetworkException('Failed to update phone: ${resp.data}');
    }
    
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw UnknownException('Unexpected error: $e');
    }
  }

  @override
  Future<void> deleteUser(int userId) async {
    final String? accessToken = await SecureStorage.read(key: 'access-token');

    if (accessToken == null) {
      throw UnauthorizedApiKeyException('Access Token not found');
    }

    try {
      final resp = await _dio.post(
        '/api/user/delete',
        data: {'id' : userId},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'} ),
      );

    if (resp.statusCode != 200) {
      throw NetworkException('Failed to delete user: ${resp.data}');
    }
    
    } on DioException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      throw UnknownException('Unexpected error: $e');
    }
  }
}