import 'package:cba_connect_application/core/network.dart';
import 'package:dio/dio.dart';
import '../core/custom_exception.dart';
import 'package:cba_connect_application/dto/chat_report_dto.dart';

abstract class ChatreportDataSource {
  Future<void> report(ReportChatDto dto);
}

class ChatreportDataSourceImpl implements ChatreportDataSource {
  final Dio _dio = Network.dio;

  ChatreportDataSourceImpl();

  @override
  Future<void> report(ReportChatDto dto) async {

    try {
      print("report chat");
      print(dto.toJson());
      await _dio.post(
        '/api/chatreport/report',
        data: dto.toJson(),
      );
    } on DioError catch (e) {
      throw NetworkException('채팅 신고 실패: ${e.message}');
    }
  }
}