import 'dart:convert';

import 'package:cba_connect_application/core/network.dart';
import 'package:dio/dio.dart';
import '../dto/create_carpool_dto.dart';
import '../models/carpool_room.dart';
import '../core/custom_exception.dart';

abstract class CarpoolDataSource {
  Future<List<CarpoolRoom>> fetchAll();
  Future<CarpoolRoom> create(CreateCarpoolDto dto);
  Future<CarpoolRoom> fetchById(int id);
}

class CarpoolDataSourceImpl implements CarpoolDataSource {
  final Dio _dio = Network.dio;

  CarpoolDataSourceImpl();

  @override
  Future<CarpoolRoom> create(CreateCarpoolDto dto) async {
    try {
      final resp = await _dio.post('/api/carpool', data: dto.toJson());
      print('▶ raw resp.data: ${resp.data} (${resp.data.runtimeType})');

      // 1) resp.data가 null인지 확인
      final raw = resp.data;
      if (raw == null) {
        throw NetworkException('서버 응답이 없습니다 (resp.data == null)');
      }

      // 2) JSON 파싱 & Map<String,dynamic> 변환
      Map<String, dynamic> body;
      if (raw is String) {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        } else {
          throw NetworkException('JSON을 Map으로 디코딩할 수 없습니다');
        }
      } else if (raw is Map) {
        // Map 타입이면 안전하게 복사
        body = Map<String, dynamic>.from(raw);
      } else {
        throw NetworkException('알 수 없는 응답 타입: ${raw.runtimeType}');
      }

      // 3) room 필드가 있으면 그걸 쓰고, 없으면 body 전체를 Room으로 간주
      final dynamic maybeRoom = body['room'];
      final Map<String, dynamic> roomMap = (maybeRoom != null)
          ? (maybeRoom is Map
          ? Map<String, dynamic>.from(maybeRoom)
          : throw NetworkException('"room" 필드가 Map이 아닙니다: ${maybeRoom.runtimeType}'))
          : body;

      return CarpoolRoom.fromJson(roomMap);

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
      return rooms.map((e) => CarpoolRoom.fromJson(e as Map<String, dynamic>)).toList();
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
}