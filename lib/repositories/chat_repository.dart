import 'package:cba_connect_application/datasources/socket/chat_socket_data_source.dart';
import 'package:cba_connect_application/models/chat.dart';

class ChatRepository {
  final _datasource = ChatSocketDatasource();

  void sendMessage(Chat message, Function(dynamic) onAck) {
    _datasource.sendMessage(message, onAck);
  }

  void listenToMessages(Function(Chat) onMessage) {
    _datasource.onMessageReceived(onMessage);
  }
}