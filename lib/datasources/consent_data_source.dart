import 'package:cba_connect_application/core/network.dart';
import 'package:cba_connect_application/models/consent.dart';
import 'package:dio/dio.dart';
import '../core/custom_exception.dart';

abstract class ConsentDataSource {
  Future<Consent> fetchConsentByUserIdAndConsentType(int userId, String concentType);
  Future<void> createConsent({ required int userId, required String consentType, required bool value });
}

class ConsentDataSourceImpl implements ConsentDataSource {
  final Dio _dio = Network.dio;

  @override
  Future<Consent> fetchConsentByUserIdAndConsentType(int userId, String consentType) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/api/consent/$userId/$consentType',
      );

      final body = resp.data!;
      final consentJson = body['consent'] as Map<String, dynamic>?;

      if (consentJson == null) {
        return Consent(
          userId: userId,
          consentType: consentType,
          value: false,
          consentedAt: null,
        );
      }

      return Consent.fromJson(consentJson);
    } on DioError catch (e) {
      throw NetworkException('동의 정보 조회 실패: ${e.message}');
    }
  }
  @override
  Future<void> createConsent({ required int userId, required String consentType, required bool value }) async {
    try {
      await _dio.post(
        '/api/consent',
        data: {
          'userId': userId,
          'consentType': consentType,
          'value': value,
        },
      );
      print("성공!!");
    } on DioError catch (e) {
      throw NetworkException('동의 정보 생성 실패: ${e.message}');
    }
  }
}