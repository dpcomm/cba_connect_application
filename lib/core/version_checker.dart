import 'package:package_info_plus/package_info_plus.dart';
import 'package:cba_connect_application/repositories/status_repository.dart';
import 'package:cba_connect_application/datasources/status_data_source.dart';
import '../core/custom_exception.dart';

class VersionChecker {
  final StatusRepository _repo;
  VersionChecker({StatusRepository? repository})
      : _repo = repository ?? StatusRepositoryImpl(StatusDataSourceImpl());

  /// 서버로부터 최신정보 가져오기.
  Future<String> _fetchLatestVersionFromServer() async {
    try {
      final appVer = await _repo.getApplicationVersion();
      return appVer.versionName;
    } on NetworkException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('최신 버전 정보 조회 중 오류: ${e.toString()}');
    }
  }

  /// 현재 설치된 앱 버전
  Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// 업데이트가 필요한지 여부
  Future<bool> isUpdateNeeded() async {
    final current = await getCurrentVersion();
    final latest = await _fetchLatestVersionFromServer();
    return current != latest;
  }

  /// 현재/최신 버전 문자열을 같이 가져오기
  Future<Map<String, String>> getVersions() async {
    final current = await getCurrentVersion();
    print("현재 버전 $current");
    final latest = await _fetchLatestVersionFromServer();
    print("최신 버전 $latest");
    return { 'current': current, 'latest': latest };
  }
}