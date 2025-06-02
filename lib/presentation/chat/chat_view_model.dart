import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/repositories/chat_repository.dart';
import 'package:cba_connect_application/models/chat.dart';

class ChatViewModel extends StateNotifier<List<(Chat, ChatStatus)>> {
  final int roomId;
  final ChatRepository _repository;

  ChatViewModel({required this.roomId, required ChatRepository repository})
    :_repository = repository, 
      super([]) {
    _repository.setRoomId(roomId);
    _repository.registerListener(_onReceived);
  }

  void _onReceived(Chat chat) {
    state = [...state, (chat, ChatStatus.success)];
  }

  Future<void> sendChat(Chat chat) async {
    state = [...state, (chat, ChatStatus.loading)];
    final sent = await _repository.sendChat(chat);
    if (sent == null) {
      state = state.map((entry) {
        final (tempChat, status) = entry;
        if (status == ChatStatus.loading && tempChat == chat) {
          return (chat, ChatStatus.failed); 
        }
        return entry;
      }).toList();      
    } else {
      state = state.map((entry) {
        final (tempChat, status) = entry;
        if (status == ChatStatus.loading && tempChat == chat) {
          return (sent, ChatStatus.success); 
        }
        return entry; 
      }).toList();      
    }
  }

  Future<void> requestUnreadMessage(Chat chat, bool alreadyEnter) async {
    final response = await _repository.requestUnreadMessage(chat, alreadyEnter);
    if(response == null) return;
    List<(Chat, ChatStatus)> list = response.map((chat) => (chat, ChatStatus.success)).toList();
    state = [...state, ...list];
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}