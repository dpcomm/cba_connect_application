class Config {
  final String baseUrl;
  final String token;
  final String _flavor;

  Config._dev()
      : baseUrl = 'http://192.168.0.166:3000',
        token = 'dev-token',
        _flavor = 'dev';

  Config._prod()
      : baseUrl = 'https://recba.me',
        token = 'prod-token',
        _flavor = 'prod';

  static late final Config instance;

  factory Config(String? flavor) {
    if (flavor == 'dev') {
      instance = Config._dev();
    } else if (flavor == 'prod') {
      instance = Config._prod();
    } else {
      throw Exception('Unknown flavor: $flavor');
    }
    return instance;
  }

  String get flavor => _flavor;
}
