import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AppConfig {
  /// 로컬 서버 (플랫폼별 호스트)
  static String get apiLocalUrl {
    if (kReleaseMode) {
      return apiProductionUrl;
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// 프로덕션 서버
  static const apiProductionUrl = 'http://121.143.179.182:8081';

  /// 실제로 쓰일 베이스 URL
  static String get apiBaseUrl => apiLocalUrl;
}