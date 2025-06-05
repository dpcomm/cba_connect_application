import 'dart:async';
import 'package:cba_connect_application/models/chat.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef AckCallback = void Function(dynamic data);

class ChatEventHandler {

  static ChatEventHandler? _instance;

  final IO.Socket socket;

  ChatEventHandler._internal(this.socket);

  factory ChatEventHandler(IO.Socket socket) {
    return _instance ??= ChatEventHandler._internal(socket);
  }

  Future<Chat?> sendChat(Chat chat) async {
    final completer = Completer<Chat>();
    socket.emitWithAck('chat', chat.toJson(chat), ack: (response) {
      completer.complete(Chat.fromJson(response['chat']));
    });
    return completer.future;
  }

  void onChat(void Function(Chat) callback) {
    socket.on('chat', (raw) {
      final chat = Chat.fromJson(raw);
      callback(chat);
    });
  }

  Future<List<Chat>?> requestUnreadMessage(Chat chat, bool requestAll) async {
    final completer = Completer<List<Chat>>();
    socket.emitWithAck(
      'request unread messages', 
      {
        'recentChat' : {
          'senderId': chat.senderId,
          'roomId': chat.roomId,
          'message': chat.message, 
          'timestamp': chat.timestamp.toIso8601String(),
        },
        'requestAll': requestAll,
      },
      ack: (response) {
        final rawList = response['chats'] as List<dynamic>;
        final rawChats = rawList.map((e) => e as Map<String, dynamic>).toList();
        
        List<Chat> chats = [];
        for (Map<String, dynamic> rawChat in rawChats) {
          chats.add(Chat.fromJson(rawChat));
        }
        completer.complete(chats);
      }
    );
    return completer.future;
  }

  Future<List<Chat>?> requestMessageLoading(Chat chat) async {
    final completer = Completer<List<Chat>>();
    socket.emitWithAck('request message loading', chat, ack: (response) {
      final rawList = response['chats'] as List<dynamic>;
      final rawChats = rawList.map((e) => e as Map<String, dynamic>).toList();

      List<Chat> chats = [];
      for (Map<String, dynamic> rawChat in rawChats) {
        chats.add(Chat.fromJson(rawChat));
      }
      completer.complete(chats);
    });
    return completer.future;  
  }

  void offChat() {
    socket.off('chat');
    // Add more as needed
  }
}