class Config {
  final String baseUrl;
  final String token;

  Config._dev()
      : baseUrl = 'http://192.168.0.233:3000',
        token = 'dev-token';

  Config._prod()
      : baseUrl = 'http://121.143.179.182:8081',
        token = 'prod-token';

  static late final Config instance;

  factory Config(String? flavor) {
    if (flavor == 'dev') {
      instance = Config._dev();
    } else if (flavor == 'prod') {
      instance = Config._prod();
    } else {
      throw Exception('Unknown flavor: $flavor');
      // instance = Config._dev();
    }
    return instance;
  }
}