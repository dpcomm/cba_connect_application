import 'package:cba_connect_application/core/custom_exception.dart';
import 'package:cba_connect_application/datasources/status_data_source.dart';
import 'package:cba_connect_application/models/application_version.dart';

abstract class StatusRepository {
  Future<ApplicationVersion> getApplicationVersion();
}

class StatusRepositoryImpl implements StatusRepository {
  final StatusDataSource _dataSource;

  StatusRepositoryImpl(this._dataSource);

  @override
  Future<ApplicationVersion> getApplicationVersion() async {
    try {
      return await _dataSource.fetchApplicationVersion();
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw UnknownException('버전 정보 조회 중 예기치 않은 오류: ${e.toString()}');
    }
  }
}