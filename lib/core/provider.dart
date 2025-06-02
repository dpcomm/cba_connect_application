import 'package:cba_connect_application/presentation/chat/chat_view_model.dart';
import 'package:cba_connect_application/repositories/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/core/socket_manager.dart';
import 'package:cba_connect_application/socket_event_handler/chat_event_handler.dart';
import 'package:cba_connect_application/models/chat.dart';

final socketManagerProvider = Provider((ref) => SocketManager());

final chatEventHandlerProvider = Provider((ref) {
  final socket = ref.watch(socketManagerProvider).socket;
  return ChatEventHandler(socket);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final handler = ref.watch(chatEventHandlerProvider);
  return ChatRepository(handler: handler);
});

final chatViewModelProvider =
    StateNotifierProvider.family<ChatViewModel, List<Chat>, RoomSenderId>((
      ref,
      roomSender,
    ) {
      final repository = ref.watch(chatRepositoryProvider);
      return ChatViewModel(
        roomId: roomSender.roomId,
        senderId: roomSender.senderId,
        repository: repository,
      );
    });
