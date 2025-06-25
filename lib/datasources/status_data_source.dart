import 'package:cba_connect_application/core/network.dart';
import 'package:dio/dio.dart';
import '../models/application_version.dart';
import '../core/custom_exception.dart';

abstract class StatusDataSource {
  Future<ApplicationVersion> fetchApplicationVersion();
}

class StatusDataSourceImpl implements StatusDataSource {
  final Dio _dio = Network.dio;

  @override
  Future<ApplicationVersion> fetchApplicationVersion() async {
    try {
      final resp = await _dio.get('/api/status/version/application');
      final data = resp.data!['version'] as Map<String, dynamic>;
      return ApplicationVersion.fromJson(data);
    } on DioError catch (e) {
      throw NetworkException('버전 정보 조회 실패: ${e.message}');
    }
  }

}
