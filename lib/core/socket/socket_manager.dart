import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cba_connect_application/config/app_config.dart';
import 'package:cba_connect_application/core/socket/socket_event_handler.dart';

class SocketManager {
  static final SocketManager _instance = SocketManager._internal();
  factory SocketManager() => _instance;

  late IO.Socket socket;
  final SocketEventHandler socketEventHandler = SocketEventHandler();

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

      socketEventHandler.setSocket(socket);
      return;      
    } catch (err) {
      print(err);
    }

  }

  void connect() {
    try {
      socketEventHandler.listenToConnect();
      socketEventHandler.listenToConnectError();
      socket.connect();
      return;
    } catch (err) {
      print(err);
    }
  } 

  void disconnect() => socket.disconnect();
}