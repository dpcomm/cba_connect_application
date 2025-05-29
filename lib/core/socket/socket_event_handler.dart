import 'package:cba_connect_application/models/chat.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef AckCallback = void Function(dynamic data);

class SocketEventHandler {

  static final SocketEventHandler _instance = SocketEventHandler._internal();
  factory SocketEventHandler() => _instance;
  SocketEventHandler._internal();

  late IO.Socket socket;

  void setSocket(IO.Socket socket) {
    this.socket = socket;
  }

  void listenToConnect() {
    try {
      socket.on('connect', (_) => print('✅ 연결됨'));
      return;
    } catch (err) {
      print(err);
    }
  }

  void listenToConnectError() {
    try {
      socket.on('connect_error', (err) => print('❌ 연결 에러: $err'));
      return;
    } catch (err) {
      print(err);
    }    
  }

  void listenToChatMessages(Function(Chat) onMessage) {
    socket.on('chat', (data) {
      final message = Chat.fromJson(data);
      onMessage(message);
    });
  }

  void sendMessage(Chat message, {AckCallback? onAck}) {
    socket.emitWithAck('chat', message, ack: (data) {
      if (onAck != null) onAck(data);
    });
  }

  void removeAllListeners() {
    socket.off('chat');
    // Add more as needed
  }
}