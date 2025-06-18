import 'dart:convert';
import 'package:cba_connect_application/core/network.dart';
import 'package:dio/dio.dart';
import '../models/address_result.dart';
import '../core/custom_exception.dart';

abstract class AddressDataSource {
  Future<List<AddressResult>> searchAddresses(String query);
}

class AddressDataSourceImpl implements AddressDataSource {
  final Dio _dio = Network.dio;
  static const _kakaoKey = '3b53dc35d67eb6ec6278dd902d1822b4';

  AddressDataSourceImpl();

  @override
  Future<List<AddressResult>> searchAddresses(String query) async {
    try {
      print("11쿼리데이터 $query");
      final response = await _dio.get(
        'https://dapi.kakao.com/v2/local/search/address.json',
        queryParameters: {'query': query, 'size': 15},
        options: Options(
            headers: {'Authorization': 'KakaoAK $_kakaoKey'},
            extra: {'skipAuth': true},
        ),
      );
      final items = (response.data['documents'] as List);
      return items.map((e) => AddressResult(
        address: e['address_name'] as String,
        lat: double.tryParse(e['y'] ?? '') ?? 0.0,
        lng: double.tryParse(e['x'] ?? '') ?? 0.0,
      )).toList();
    } on DioError catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedApiKeyException('카카오 API 키가 유효하지 않습니다.');
      }
      throw NetworkException('주소 검색 중 오류가 발생했습니다.');
    }
  }
}
