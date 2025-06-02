import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/models/chat.dart';
import 'package:cba_connect_application/repositories/chat_repository.dart';
import 'package:uuid/uuid.dart';

// 메세지 전송 상태값 enum (메세지 서버 전송 성공 여부)
enum SendMessageStatus { initial, sending, success, error }

// 메세지 상태 관리 요소 클래스
class ChatMessageWithStatus {
  final Chat chat;
  final String localId;
  SendMessageStatus status;

  ChatMessageWithStatus({
    required this.chat,
    required this.localId,
    this.status = SendMessageStatus.initial,
  });
}

// 프로바이더에 넘기기 위한 데이터 클래스
class RoomSenderId {
  final int roomId;
  final int senderId;

  RoomSenderId({required this.roomId, required this.senderId});

  // Provider 키로 사용할 때 값 비교를 위해 ==와 hashCode를 재정의함
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomSenderId &&
          runtimeType == other.runtimeType &&
          roomId == other.roomId &&
          senderId == other.senderId;

  @override
  int get hashCode => roomId.hashCode ^ senderId.hashCode;
}

// ChatViewModel
class ChatViewModel extends StateNotifier<List<Chat>> {
  final int roomId;
  final int senderId;
  final ChatRepository repository;

  // 전송 중 또는 실패한 메시지 (로컬 상태)
  final List<ChatMessageWithStatus> _sendingMessages = [];

  ChatViewModel({
    required this.roomId,
    required this.senderId,
    required this.repository,
  }) : super([]) {
    _init();
  }

  // 초기 메세지 불러오기
  Future<void> _init() async {
    try {
      final messages = await repository.fetchMessages(roomId);
      receiveMessages(messages);
    } catch (e) {
      print('초기 메세지 불러오기 실패: $e');
      receiveMessages([]); // 실패 시 빈 상태 세팅
    }
  }

  // receiveMessages : 서버에서 수신한 메시지 목록 state에 설정
  void receiveMessages(List<Chat>? messages) {
    if (messages != null) {
      state = messages;
    }
  }

  // 메세지 전송
  Future<void> sendMessage(String message) async {
    final chat = Chat(
      senderId: senderId,
      roomId: roomId,
      message: message,
      timestamp: DateTime.now(),
    );

    final localId = const Uuid().v4();
    final sending = ChatMessageWithStatus(
      chat: chat,
      localId: localId,
      status: SendMessageStatus.sending,
    );
    _sendingMessages.add(sending);

    try {
      await repository.sendChat(chat);
      // 성공 시 sendingMessages에서 삭제
      _sendingMessages.removeWhere((e) => e.localId == localId);
      state = [...state, chat];
    } catch (_) {
      // 실패 시 상태 error로 변경
      sending.status = SendMessageStatus.error;
    }
  }

  // 전송 실패한 메시지 삭제
  void deleteFailedMessage(String localId) {
    _sendingMessages.removeWhere(
      (e) => e.localId == localId && e.status == SendMessageStatus.error,
    );
  }

  // 전송 실패한 메시지 재전송
  Future<void> retryFailedMessage(Chat chat) async {
    deleteFailedMessageByChat(chat);
    await sendMessage(chat.message);
  }

  /// (편의용) Chat(message & timestamp)으로 실패 메시지 제거
  void deleteFailedMessageByChat(Chat chat) {
    _sendingMessages.removeWhere(
      (e) =>
          e.chat.message == chat.message &&
          e.chat.timestamp == chat.timestamp &&
          e.status == SendMessageStatus.error,
    );
  }

  // UI에 표시할 메시지 리스트 반환 (서버 + 전송 실패)
  List<dynamic> get mergedMessages {
    return [
      ...state, // 서버로부터 받은 정상 메세지 리스트 List<Chat>
      ..._sendingMessages.where((e) => e.status == SendMessageStatus.error),
    ]..sort((a, b) => a.chat.timestamp.compareTo(b.chat.timestamp));
  }
}
