import 'package:flutter/foundation.dart';

class AppConfig {
  /// 로컬 서버
  static const apiLocalUrl = 'http://localhost:3000';

  /// 프로덕션 서버
  static const apiProductionUrl = 'http://121.143.179.182:8081';

  static String get apiBaseUrl {
    return kReleaseMode ? apiProductionUrl : apiLocalUrl;
  }
}