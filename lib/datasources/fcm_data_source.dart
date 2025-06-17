import 'package:cba_connect_application/core/network.dart';
import 'package:dio/dio.dart';
import '../dto/regist_fcm_dto.dart';
import '../models/fcmToken.dart';
import '../core/custom_exception.dart';

abstract class FcmDataSource {
  Future<FcmToken> regist(RegistFcmDto dto);
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
}