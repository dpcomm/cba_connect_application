import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/models/chat.dart';
import 'package:cba_connect_application/models/chat_item.dart';
import 'package:cba_connect_application/repositories/chat_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';

class ChatViewModel extends StateNotifier<List<ChatItem>> {
  final int roomId;
  final ChatRepository _repository;
  final Ref ref;

  int? currentUserId;

  ChatViewModel({
    required this.roomId,
    required ChatRepository repository,
    required this.ref,
  }) : _repository = repository,
       super([]) {
    print('[ChatViewModel] 생성자 호출, $roomId번 채팅방');

    _repository.setRoomId(roomId);
    print('[ChatViewModel]setRoomId => $roomId');

    _init();

    // 마지막 registerListener
    _repository.registerListener(_onReceived);
    print('[ChatViewModel]레포지토리 설정 완료, 서버 메시지 수신 대기 시작');

    // ref.onDispose를 사용하여 뷰모델이 dispose될 때 저장 로직 실행 보장
    ref.onDispose(() async {
      print('[ChatViewModel][ref.onDispose] 뷰모델 종료 감지, Prefs 저장 시작');

      // 현재 state의 스냅샷을 먼저 생성하여, dispose 후에도 접근 가능하게 함
      final currentStateSnapshot = List.of(state); // List.of()를 사용하여 깊은 복사

      await _saveRecentMessagesToPrefs(
        currentStateSnapshot,
      ); // 비동기 작업이지만, dispose 시점에는 완료까지 기다릴 필요는 없음
      print('[ChatViewModel][ref.onDispose] Prefs 저장 완료');
    });
  }

  // 초기 메세지 불러오기
  Future<void> _init() async {
    try {
      final loginState = ref.watch(loginViewModelProvider);
      currentUserId = loginState.user?.id;
      print('[ChatViewModel][_init] currentUserId=$currentUserId');

      // 1) 로컬(Prefs)에 저장된 최근 50개 메세지 불러와서 state에 저장
      final cached = await _loadMessagesFromPrefs();
      if (cached.isNotEmpty) {
        print('[ChatViewModel][_init] 캐시된 메시지 로드: ${cached.length}개');
        state = cached;
        print('[ChatViewModel][_init] 캐시된 메시지 로드 후 state: ${state.length}개');
      } else {
        print('[ChatViewModel][_init] 캐시된 메시지 없음');
      }

      // 2) 서버에서 이전 메세지 및 안읽은 메세지 로드
      await _loadMessagesFromServer();
    } catch (e) {
      print('[ChatViewModel][_init] 초기 메세지 불러오기 실패: $e');
    }
  }

  // 서버에서 이전 메시지 및 읽지 않은 메시지 로드 및 처리
  Future<void> _loadMessagesFromServer() async {
    // 1) 로컬저장 이전 메세지 불러오기
    // state가 비어있지 않은 경우(로컬에 저장된 메세지 있는 경우)
    if (state.isNotEmpty) {
      final firstItem = state.first;
      if (firstItem is ChatMessageItem) {
        // 로컬 oldest 메세지
        final stateOldestChat = firstItem.chat; // Chat
        print('[ChatViewModel][_loadMessagesFromServer] 캐시된 가장 오래된(첫번째) 메세지: ${stateOldestChat.message}');

        // 서버에서 stateOldestChat 이전 메세지들 로드
        final previousMessages = await _repository.loadChats(stateOldestChat);
        if (previousMessages != null && previousMessages.isNotEmpty) {
          // 서버에서 받아온 이전 메세지들 -> ChatMessageItem으로 변환
          final previousChatItems =
              previousMessages
                  .map((chat) => ChatMessageItem(chat: chat, status: ChatStatus.success),)
                  .toList();

          // 이전 메세지들을 state 앞에 추가
          state = [...previousChatItems, ...state];
          print('[ChatViewModel][_loadMessagesFromServer] 서버에서 이전 메시지 ${previousChatItems.length}개 로드 및 추가');
        } else {
          print('[ChatViewModel][_loadMessagesFromServer] 서버에서 이전 메시지 없음');
        }
      }
    } else {
       print('[ChatViewModel][_loadMessagesFromServer] state(로컬) 비어있음');
    }

    // 2) recentChat 이후 안읽은 메세지 불러오기
    // state가 비어있지 않은 경우(로컬에 저장된 메세지 있는 경우)
    print('[ChatViewModel][_loadMessagesFromServer] 안 읽은 메시지 요청 로직 시작');

    if (state.isNotEmpty) {
      final lastItem = state.last;

      if (lastItem is ChatMessageItem) {
        final recentChat = lastItem.chat;
        print('[ChatViewModel][_loadMessagesFromServer] 서버에서 안읽은 메세지 요청 시도 : recentChat=${recentChat.message}');
        await requestUnreadMessage(recentChat, false); // *** alreadyEnter bool 수정해야함!! ***
      } else {
        // state에 메시지가 있지만 ChatMessageItem이 아닌 경우 (ex: DividerItem 등)
        print('[ChatViewModel][_loadMessagesFromServer] 마지막 항목이 ChatMessageItem이 아니므로 안 읽은 메시지 요청 스킵');
        print('실제 타입: ${lastItem.runtimeType}');
      }
    } else {
      // *** recentChat 없는 경우 안읽음 메세지 불러오기 추가해야함!! ***
      print('[ChatViewModel][_loadMessagesFromServer] state(로컬) 비어있어서 안 읽은 메세지 요청 스킵 - 추가 로직 필요');
    }
  }

  void _onReceived(Chat chat) {
    print('[ChatViewModel][_onReceived 시작] state => ${state.length}개');
    print('[ChatViewModel][_onReceived] 메시지 수신: ${chat.message} (senderId=${chat.senderId})');
    // 수신된 Chat을 ChatMessageItem으로 변환하여 추가
    state = [...state, ChatMessageItem(chat: chat, status: ChatStatus.success)];
    print('[ChatViewModel][_onReceived 끝] state => ${state.length}개');
  }

  // 전송하려는 message => Chat 생성
  Future<void> sendMessage(String message) async {
    if (currentUserId == null) {
      print('[ChatViewModel][sendMessage] currentUserId가 설정되지 않음. 메시지 전송 불가');
      return;
    }

    final chat = Chat(
      senderId: currentUserId!,
      roomId: roomId,
      message: message,
      timestamp: DateTime.now(),
    );
    print('[ChatViewModel][sendMessage] Chat 생성: ${chat.message}, ${chat.timestamp}');

    await sendChat(chat);
  }

  // sendChat: Chat 객체를 받아 전송
  Future<void> sendChat(Chat chat) async {
    print('[ChatViewModel][sendChat] 메시지 전송 시도: ${chat.message}');

    final sendingChatItem = ChatMessageItem(
      chat: chat,
      status: ChatStatus.loading,
    );
    state = [...state, sendingChatItem];
    print('[ChatViewModel][sendChat] state 상태 업데이트(1) - 총 state 수: ${state.length}');

    final sent = await _repository.sendChat(chat);

    state =
        state.map((item) {
          if (item is ChatMessageItem &&
              item.status == ChatStatus.loading &&
              item.chat == chat) {
            if (sent == null) {
              // 전송 실패한 경우
              print('[ChatViewModel][sendChat] 메시지 전송 실패: ${chat.message}');
              return ChatMessageItem(chat: chat, status: ChatStatus.failed);
            } else {
              // 전송 성공한 경우
              print('[ChatViewModel][sendChat] 메시지 전송 성공: ${chat.message}');
              return ChatMessageItem(chat: chat, status: ChatStatus.success);
            }
          }
          return item;
        }).toList();
    print('[ChatViewModel][sendChat] state 상태 업데이트(3) - 총 state 수: ${state.length}');
  }

  // 안읽은 메세지 불러오기 (recentChat 기준)
  Future<void> requestUnreadMessage(Chat chat, bool alreadyEnter) async {
    print('[ChatViewModel][requestUnreadMessage] 안 읽은 메시지 요청');

    final response = await _repository.requestUnreadMessage(chat, alreadyEnter);
    if (response == null || response.isEmpty) {
      print('[ChatViewModel][requestUnreadMessage] 응답 없거나 비어있음');
      return;
    }
    print('[ChatViewModel][requestUnreadMessage] 응답받은 response 메시지 수: ${response.length}개',);

    // '여기까지 읽었습니다' 구분선 추가
    final List<ChatItem> itemsToAdd = [];
    // 로컬에 메세지 있었고, 서버에서 안읽은 메세지가 왔을 때만 구분선 추가
    if (state.isNotEmpty) {
      itemsToAdd.add(UnreadDividerItem(text: '---여기까지 읽었습니다---'));
      print('[ChatViewModel][requestUnreadMessage] "--여기까지 읽었습니다--" 구분선 추가');
    }

    // 받아온 Chat 리스트를 ChatMessageItem 리스트로 변환하여 state에 추가
    final unreadChatItems =
        response.map((chat) => ChatMessageItem(chat: chat, status: ChatStatus.success))
                .toList();
    itemsToAdd.addAll(unreadChatItems); // 안 읽은 메시지들을 구분선 뒤에 추가
    // 구분선 + 안 읽은 메세지들 state에 추가
    state = [...state, ...itemsToAdd];
    print('[ChatViewModel][requestUnreadMessage] state 상태 업데이트 - 총 state 수: ${state.length}');
  }

  // 로컬(Prefs)에 저장된 최근 50개 메세지 불러오기
  Future<List<ChatItem>> _loadMessagesFromPrefs() async {
    print('[ChatViewModel][_loadMessagesFromPrefs] 로컬에서 메시지 불러오기 시작');

    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString('chat_cache_$roomId');
      if (raw == null) {
        print('[ChatViewModel][_loadMessagesFromPrefs] 저장된 메시지 없음');
        return [];
      }
      final List decoded = jsonDecode(raw);
      print('[ChatViewModel][_loadMessagesFromPrefs] ${decoded.length}개의 메시지 디코딩 완료');

      final loadedChatItems = <ChatItem>[];

      // 일부 메시지 손상만 있어도 전체 캐시 삭제 없이 나머지를 살리기
      for (final e in decoded) {
        try {
          final chat = Chat.fromJson(e['chat']);
          final status = ChatStatus.values.byName(e['status']);
          loadedChatItems.add(ChatMessageItem(chat: chat, status: ChatStatus.success));
        } catch (e) {
          print('[ChatViewModel][_loadMessagesFromPrefs] 개별 메시지 파싱 오류: $e');
        }
      }
      return loadedChatItems;
    } catch (e) {
      print('[ChatViewModel][_loadMessagesFromPrefs] 메시지 디코딩 중 오류 발생: $e');
      await prefs.remove('chat_cache_$roomId');
      return [];
    }
  }

  // 최근 메세지 50개 Prefs에 저장하기
  Future<void> _saveRecentMessagesToPrefs(
    List<ChatItem> chatItemsToSave,
  ) async {
    print('[ChatViewModel][_saveRecentMessagesToPrefs] 최근 메시지 저장 시작');

    final prefs = await SharedPreferences.getInstance();

    // 마지막 50개 메세지
    final lastChat50 =
        chatItemsToSave
            .whereType<ChatMessageItem>() // ChatMessageItem만 필터링
            .toList();

    final messeagesToProcess =
        lastChat50.length <= 50
            ? lastChat50
            : lastChat50.sublist(lastChat50.length - 50);

    print('[ChatViewModel][_saveRecentMessagesToPrefs] 저장될 마지막 메세지: ${messeagesToProcess.isEmpty ? "없음" : messeagesToProcess.last.chat.message}');

    final jsonList =
        messeagesToProcess
            .map((item) => {
                'chat': item.chat.toJson(),
                'status': item.status.name, // Enum type
              },)
            .toList();

    final jsonString = jsonEncode(jsonList);
    await prefs.setString('chat_cache_$roomId', jsonString);

    print('[ChatViewModel][_saveRecentMessagesToPrefs] ${messeagesToProcess.length}개의 메시지 저장 완료');
  }

  @override
  void dispose() {
    print('[ChatViewModel][dispose] 뷰모델 dispose 메서드 호출됨 (저장 로직은 ref.onDispose에서 처리)');
    _repository.dispose();
    super.dispose();
  }
}
