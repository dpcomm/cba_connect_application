import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cba_connect_application/config/app_config.dart';

class SocketManager {
  static final SocketManager _instance = SocketManager._internal();
  factory SocketManager() => _instance;

  late IO.Socket socket;

  SocketManager._internal();


  void setSocket(String token) {
    try {
      socket = IO.io(
        AppConfig.apiBaseUrl, <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': true,
          'extraHeaders': {
            'authorization': 'Bearer $token',
          },
        },
      );

      return;      
    } catch (err) {
      print(err);
    }

  }

  void connect() {
    try {
      socket.on('connect', (_) => print('✅ 연결됨'));
      socket.on('connect_error', (err) => print('❌ 연결 에러: $err'));
      socket.connect();
      return;
    } catch (err) {
      print(err);
    }
  } 

  void disconnect() => socket.disconnect();
}