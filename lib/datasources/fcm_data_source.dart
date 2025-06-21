import 'package:cba_connect_application/core/network.dart';
import 'package:cba_connect_application/dto/delete_fcm_token_dto.dart';
import 'package:cba_connect_application/dto/refresh_fcm_token_dto.dart';
import 'package:dio/dio.dart';
import '../dto/regist_fcm_dto.dart';
import '../models/fcmToken.dart';
import '../core/custom_exception.dart';

abstract class FcmDataSource {
  Future<FcmToken> regist(RegistFcmDto dto);
  Future<FcmToken> delete(DeleteFcmTokenDto dto);
  Future<FcmToken> refresh(RefreshFcmTokenDto dto);
}

class FcmDataSourceImpl implements FcmDataSource {
  final Dio _dio = Network.dio;

  FcmDataSourceImpl();

  @override
  Future<FcmToken> regist(RegistFcmDto dto) async {
    try {
      print("sending regist token request");
      final resp = await _dio.post(
        '/api/fcm/regist',
        data: dto.toJson(),
      );
      final payload = resp.data as Map<String, dynamic>;
      final userId = payload['userId'] as int;
      final token = payload['token'] as String;
      return FcmToken(userId: userId, token: token);      
    } on DioError catch (e) {
      throw NetworkException('토큰 등록 실패: ${e.message}');
    }
  }

  @override
  Future<FcmToken> delete(DeleteFcmTokenDto dto) async {
    try {
      final resp = await _dio.post(
        '/api/fcm/delete',
        data: dto.toJson(),
      );
      final payload = resp.data as Map<String, dynamic>;
      final userId = payload['userId'] as int;
      final token = payload['token'] as String;
      return FcmToken(userId: userId, token: token);
    } on DioError catch (e) {
      throw NetworkException('토큰 삭제 실패: ${e.message}');
    }

  }

  @override
  Future<FcmToken> refresh(RefreshFcmTokenDto dto) async {
    try {
      final resp = await _dio.post(
        '/api/fcm/refresh',
        data: dto.toJson(),
      );
      final payload = resp.data as Map<String, dynamic>;
      final userId = payload['userId'] as int;
      final newToken = payload['newToken'] as String;
      return FcmToken(userId: userId, token: newToken);      
    } on DioError catch (e) {
      throw NetworkException('토큰 등록 실패: ${e.message}');
    }
  }
}