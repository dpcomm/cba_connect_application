import 'package:cba_connect_application/core/network.dart';
import 'package:dio/dio.dart';
import '../dto/create_carpool_dto.dart';
import '../models/carpool_room.dart';
import '../core/custom_exception.dart';

abstract class CarpoolDataSource {
  Future<List<CarpoolRoom>> fetchAll();
  Future<CarpoolRoom> create(CreateCarpoolDto dto);
  Future<CarpoolRoom> fetchById(int id);
  Future<List<CarpoolRoom>> fetchMyCarpools(int userId);
  Future<void> joinCarpool(int userId, int roomId);
  Future<void> leaveCarpool(int userId, int roomId);
  Future<void> deleteCarpool(int roomId);
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

  @override
  Future<List<CarpoolRoom>> fetchAll() async {
    try {
      final resp = await _dio.get('/api/carpool');
      final data = resp.data as Map<String, dynamic>;
      final rooms = data['rooms'] as List;
      return rooms
          .map((e) => CarpoolRoom.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioError catch (e) {
      throw NetworkException('카풀 목록 조회 실패: ${e.message}');
    }
  }

  @override
  Future<CarpoolRoom> fetchById(int id) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('/api/carpool/$id');
      final data = resp.data as Map<String, dynamic>;
      final roomJson = data['room'] as Map<String, dynamic>;
      return CarpoolRoom.fromJson(roomJson);
    } on DioError catch (e) {
      throw NetworkException('카풀 조회 실패: ${e.message}');
    }
  }

  @override
  Future<List<CarpoolRoom>> fetchMyCarpools(int userId) async {
    try {
      final resp = await _dio.get(
          '/api/carpool/my', queryParameters: {'userId': userId});
      final data = resp.data as Map<String, dynamic>;
      final rooms = data['rooms'] as List;
      return rooms
          .map((e) => CarpoolRoom.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NetworkException('마이 카풀 목록 조회 실패: ${e.message}');
    }
  }

  @override
  Future<void> joinCarpool(int userId, int roomId) async {
    try {
      await _dio.post('/api/carpool/join', data: {
        'userId': userId,
        'roomId': roomId,
      });
    } on DioError catch (e) {
      final code = e.response?.statusCode;
      final body = e.response?.data;
      if (code == 400 && body is Map && body['message'] != null) {
        throw NetworkException('카풀 참여 실패: ${body['message']}');
      }
      throw NetworkException('카풀 참여 실패: ${e.message}');
    }
  }

  @override
  Future<void> leaveCarpool(int userId, int roomId) async {
    try {
      await _dio.post(
        '/api/carpool/leave',
        data: {
          'userId': userId,
          'roomId': roomId,
        },
      );
    } on DioError catch (e) {
      throw NetworkException('카풀 나가기 실패: ${e.message}');
    }
  }

  @override
  Future<void> deleteCarpool(int roomId) async {
    try {
      await _dio.post(
        '/api/carpool/delete/$roomId',
      );
    } on DioError catch (e) {
      throw NetworkException('카풀 방 삭제 실패: ${e.message}');
    }
  }
}