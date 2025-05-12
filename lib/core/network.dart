import 'package:dio/dio.dart';
import '../config/app_config.dart';

class Network {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
    ),
  );
}
