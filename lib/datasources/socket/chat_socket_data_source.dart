import 'package:cba_connect_application/models/chat.dart';
import 'package:cba_connect_application/core/socket/socket_event_handler.dart';

class ChatSocketDatasource {
  final _handler = SocketEventHandler();

  void sendMessage(Chat message, Function(dynamic) onAck) {
    _handler.sendMessage(message, onAck: onAck);
  }

  void onMessageReceived(Function(Chat) callback) {
    _handler.listenToChatMessages(callback);
  }
}