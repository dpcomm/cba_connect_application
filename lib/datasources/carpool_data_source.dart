import 'package:cba_connect_application/core/network.dart';
import 'package:dio/dio.dart';
import '../dto/create_carpool_dto.dart';
import '../models/carpool_room.dart';
import '../core/custom_exception.dart';

abstract class CarpoolDataSource {
  Future<CarpoolRoom> create(CreateCarpoolDto dto);
}

class CarpoolDataSourceImpl implements CarpoolDataSource {
  final Dio _dio = Network.dio;

  CarpoolDataSourceImpl();

  @override
  Future<CarpoolRoom> create(CreateCarpoolDto dto) async {
    try {
      final resp = await _dio.post(
        '/api/carpool',
        data: dto.toJson(),
      );
      final payload = resp.data as Map<String, dynamic>;
      final roomJson = payload['room'] as Map<String, dynamic>;
      return CarpoolRoom.fromJson(roomJson);
    } on DioError catch (e) {
      throw NetworkException('카풀 생성 실패: ${e.message}');
    }
  }
}