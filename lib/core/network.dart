import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'secure_storage.dart';

class Network {
  static final Dio dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: 15000),
      receiveTimeout: const Duration(milliseconds: 15000),
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.read(key: 'access-token');
          print('▶ Authorization header: Bearer $token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (err, handler) async {
          final response = err.response;
          final requestOptions = err.requestOptions;
          if (response?.statusCode == 401 && requestOptions.extra['retried'] != true) {
            try {
              final refreshToken = await SecureStorage.read(key: 'refresh-token');
              final accessToken  = await SecureStorage.read(key: 'access-token');

              final response = await dio.post(
                '/api/user/refresh',
                data: {
                  'accessToken': accessToken,
                  'refreshToken': refreshToken,
                },
              );

              final newAccess = response.data['accessToken'] as String;

              await SecureStorage.write(key: 'access-token', value: newAccess);

              requestOptions.headers['Authorization'] = 'Bearer $newAccess';

              requestOptions.extra['retried'] = true;

              final cloned = await dio.fetch(requestOptions);
              return handler.resolve(cloned);
            } catch (e) {
              /** 로그인 만료 알림 떠야함. */
              return handler.next(err);
            }
          }

          return handler.next(err);
        },
      ),
    );

    return dio;
  }
}
