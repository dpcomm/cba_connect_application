class Config {
  final String baseUrl;
  final String token;

  Config._dev()
      : baseUrl = 'http://localhost:3000',
        token = 'dev-token';

  Config._product()
      : baseUrl = 'http://121.143.179.182:8081',
        token = 'prod-token';

  static late final Config instance;

  factory Config(String? flavor) {
    if (flavor == 'dev') {
      instance = Config._dev();
    } else if (flavor == 'product') {
      instance = Config._product();
    } else {
      throw Exception('Unknown flavor: $flavor');
      // instance = Config._dev();
    }
    return instance;
  }
}