import 'package:cba_connect_application/dto/chat_report_dto.dart';
import 'package:cba_connect_application/datasources/chat_report_datasource.dart';

abstract class ChatreportRepository {
  Future<void> report(ReportChatDto dto);
}

class ChatreportRepositoryImpl implements ChatreportRepository {
  final ChatreportDataSource _ds;
  ChatreportRepositoryImpl(this._ds);

  @override
  Future<void> report(ReportChatDto dto) {
    print("chat report repository report chat");
    return _ds.report(dto);
  }
}
