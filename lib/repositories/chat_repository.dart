import 'package:cba_connect_application/socket_event_handler/chat_event_handler.dart';
import 'package:cba_connect_application/models/chat.dart';

class ChatRepository {
  final ChatEventHandler _handler;
  int? _senderId;
  int? _roomId;
  List<Chat> _cache = [];

  ChatRepository({required ChatEventHandler handler}) : _handler = handler;

  void setSenderId(int senderId) {
    _senderId = senderId;
  }

  void setRoomId(int roomId) {
    _roomId = roomId;
  }

  Future<List<Chat>?> loadChats(Chat chat) async {
    final response = await _handler.requestMessageLoading(chat);
    if (response == null) return null;
    _cache = [...response, ..._cache];
    return response;
  }

  Future<Chat?> sendChat(Chat chat) async {
    final response = await _handler.sendChat(chat);
    if (response == null) return null;
    _cache.add(response);
    if (response.roomId != _roomId) return null; //기능 추가 가능
    return response;
  }

  void handleIncoming(Chat chat) {
    if (chat.roomId == _roomId) {
      _cache.add(chat);
      _onChatReceived?.call(chat);
    }
  }

  Future<List<Chat>?> requestUnreadMessage(Chat? chat, bool requestAll) async {
    chat ??= Chat(
      senderId: _senderId!,
      roomId: _roomId!,
      message: "request unread messages",
      timestamp: DateTime.now(),
    );    
    final response = await _handler.requestUnreadMessage(chat, requestAll);
    if (response == null) return null;
    _cache = [..._cache, ...response];
    return response;
  }

  void Function(Chat)? _onChatReceived;

  void registerListener(void Function(Chat) onReceived) {
    _onChatReceived = onReceived;
    _handler.onChat(handleIncoming);
  }

  void dispose() => _handler.offChat();
}
