import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/models/chat.dart';
import 'package:cba_connect_application/repositories/chat_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';

class ChatViewModel extends StateNotifier<List<(Chat, ChatStatus)>> {
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

      // 로컬(Prefs)에 저장된 최근 50개 메세지 불러와서 state에 저장
      final cached = await _loadMessagesFromPrefs();
      if (cached.isNotEmpty) {
        print('[ChatViewModel][_init] 캐시된 메시지 로드: ${cached.length}개');
        state = cached;
        print('[ChatViewModel] [_init] 캐시된 메시지 로드 후 state: ${state.length}개');
      } else {
        print('[ChatViewModel][_init] 캐시된 메시지 없음');
      }

      // recentChat
      if (state.isNotEmpty) {
        final recentChat = state.last.$1; // Chat
        await requestUnreadMessage(recentChat, false);
      } else {
        // state 비어있는 경우(recentChat이 없는경우)
        // while???
        // await requestUnreadMessage(recentChat, false);
      }

      // await _loadInitialMessagesFromServer();
      // 초기 메세지 불러오는 부분??
      // final messages = await _repository.fetchMessages(roomId);
      // receiveMessages(messages);  // 서버에서 수신한 메세지 목록 state에 설정
    } catch (e) {
      print('초기 메세지 불러오기 실패: $e');
      // receiveMessages([]); // 실패 시 빈 상태 세팅
    }
  }

  void _onReceived(Chat chat) {
    print('[ChatViewModel][_onReceived 시작] state => ${state.length}개');
    print(
      '[ChatViewModel][_onReceived] 메시지 수신: ${chat.message} (senderId=${chat.senderId})',
    );
    state = [...state, (chat, ChatStatus.success)];
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
    print(
      '[ChatViewModel][sendMessage] Chat 생성: ${chat.message}, ${chat.timestamp}',
    );

    await sendChat(chat);
  }

  // sendChat
  Future<void> sendChat(Chat chat) async {
    print('[ChatViewModel][sendChat] 메시지 전송 시도: ${chat.message}');

    state = [...state, (chat, ChatStatus.loading)];
    print(
      '[ChatViewModel][sendChat] state 상태 업데이트(1) - 총 state 수: ${state.length}',
    );

    final sent = await _repository.sendChat(chat);

    if (sent == null) {
      // 전송 실패한 경우
      print('[ChatViewModel][sendChat] 메시지 전송 실패: ${chat.message}');
      state =
          state.map((entry) {
            final (tempChat, status) = entry;
            if (status == ChatStatus.loading && tempChat == chat) {
              return (chat, ChatStatus.failed);
            }
            return entry;
          }).toList();
    } else {
      // 전송 성공한 경우
      print('[ChatViewModel][sendChat] 메시지 전송 성공: ${sent.message}');
      print(
        '[ChatViewModel][sendChat] state 상태 업데이트(2) - 총 state 수: ${state.length}',
      );
      state =
          state.map((entry) {
            final (tempChat, status) = entry;
            if (status == ChatStatus.loading && tempChat == chat) {
              return (sent, ChatStatus.success);
            }
            return entry;
          }).toList();
      print(
        '[ChatViewModel][sendChat] state 상태 업데이트(3) - 총 state 수: ${state.length}',
      );
    }
  }

  // 안읽은 메세지 불러오기
  Future<void> requestUnreadMessage(Chat chat, bool alreadyEnter) async {
    print('[ChatViewModel][requestUnreadMessage] 안 읽은 메시지 요청');

    final response = await _repository.requestUnreadMessage(chat, alreadyEnter);
    if (response == null) {
      print('[ChatViewModel][requestUnreadMessage] 응답 없음');
      return;
    }
    print(
      '[ChatViewModel][requestUnreadMessage] 응답받은 response 메시지 수: ${response.length}개',
    );

    List<(Chat, ChatStatus)> list =
        response.map((chat) => (chat, ChatStatus.success)).toList();
    state = [...state, ...list];
    print(
      '[ChatViewModel][requestUnreadMessage] state 상태 업데이트 - 총 state 수: ${state.length}',
    );
  }

  // 로컬(Prefs)에 저장된 최근 50개 메세지 불러오기
  Future<List<(Chat, ChatStatus)>> _loadMessagesFromPrefs() async {
    print('[ChatViewModel][_loadMessagesFromPrefs] 로컬에서 메시지 불러오기 시작');

    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString('chat_cache_$roomId');
      if (raw == null) {
        print('[ChatViewModel][_loadMessagesFromPrefs] 저장된 메시지 없음');
        return [];
      }
      final List decoded = jsonDecode(raw);
      print(
        '[ChatViewModel][_loadMessagesFromPrefs] ${decoded.length}개의 메시지 디코딩 완료',
      );

      final loadedMessages = <(Chat, ChatStatus)>[];

      // 일부 메시지 손상만 있어도 전체 캐시 삭제 없이 나머지를 살리기
      for (final e in decoded) {
        try {
          final chat = Chat.fromJson(e['chat']);
          final status = ChatStatus.values.byName(e['status']);
          loadedMessages.add((chat, status));
        } catch (e) {
          print('[ChatViewModel][_loadMessagesFromPrefs] 개별 메시지 파싱 오류: $e');
        }
      }
      return (loadedMessages);
    } catch (e) {
      print('[ChatViewModel][_loadMessagesFromPrefs] 메시지 디코딩 중 오류 발생: $e');
      await prefs.remove('chat_cache_$roomId');
      return [];
    }
  }

  // 초기 메세지 전부 불러오기 (추가해야 함)
  Future<void> _loadInitialMessagesFromServer() async {
    print('[ChatViewModel][_loadInitialMessagesFromServer] 서버로부터 초기 메시지 로딩');

    // final loadedMessages = <(Chat, ChatStatus)>[];
    // loadedMessages = await _repository.fetchMessages(roomId);

    // 이전 코드
    //   final messages = await _repository.fetchMessages(roomId);
    //   if (messages == null) {
    //     print('[ChatViewModel][_loadInitialMessagesFromServer] 메시지 없음');
    //     return;
    //   }

    //   final chatList =
    //       messages.map((chat) => (chat, ChatStatus.success)).toList();
    //   state = [...state, ...chatList];

    //   print(
    //     '[ChatViewModel][_loadInitialMessagesFromServer] ${chatList.length}개 메시지 불러옴',
    //   );
  }

  // 최근 메세지 Prefs에 저장하기
  Future<void> _saveRecentMessagesToPrefs(
    List<(Chat, ChatStatus)> messagesToSave,
  ) async {
    print('[ChatViewModel][_saveRecentMessagesToPrefs] 최근 메시지 저장 시작');

    final prefs = await SharedPreferences.getInstance();

    // 마지막 50개 메세지
    final lastChat50 =
        messagesToSave.length <= 50
            ? messagesToSave
            : messagesToSave.sublist(messagesToSave.length - 50);

    print('[ChatViewModel][_saveRecentMeesagesToPrefs] ${lastChat50.last}');

    final jsonList =
        lastChat50
            .map(
              (e) => {
                'chat': e.$1.toJson(e.$1),
                'status': e.$2.name, // Enum type
              },
            )
            .toList();

    final jsonString = jsonEncode(jsonList);
    await prefs.setString('chat_cache_$roomId', jsonString);

    print(
      '[ChatViewModel][_saveRecentMeesagesToPrefs] ${lastChat50.length}개의 메시지 저장 완료',
    );
  }

  // Future<void> closeViewModel() async {
  //   await _saveRecentMessagesToPrefs();
  //   dispose();
  // }

  @override
  void dispose() {
    print(
      '[ChatViewModel][dispose] 뷰모델 dispose 메서드 호출됨 (저장 로직은 ref.onDispose에서 처리)',
    );
    _repository.dispose();
    super.dispose();
  }
}
