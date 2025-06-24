import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/models/chat.dart';
import 'package:cba_connect_application/models/chat_item.dart';
import 'package:cba_connect_application/repositories/chat_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';
import 'dart:async';
import 'package:collection/collection.dart'; // lastOrNull, firstOrNull 사용을 위해 추가
import 'package:intl/intl.dart'; // DateFormat 사용을 위해 추가
import 'package:flutter/material.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/core/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cba_connect_application/core/socket_manager.dart';

class ChatViewModel extends StateNotifier<List<ChatItem>> {
  final int roomId;
  final ChatRepository _repository;
  final CarpoolRepository _carpoolRepository;
  final Ref ref;

  int? currentUserId;
  Map<int, String> _membersMap = {};

  bool _isLoadingPreviousMessages = false; // 이전 메시지 로드 중 플래그 추가
  bool _hasMorePreviousMessages = true; // 서버에 더 불러올 '이전' 메시지가 있는지 여부

  // 초기 스크롤 결정을 위한 플래그
  bool _isCacheEmptyOnInitialLoad = false;
  bool _hasUnreadMessagesDivider = false;

  final _scrollToBottomController = StreamController<void>.broadcast();
  Stream<void> get scrollToBottomStream => _scrollToBottomController.stream;

  final _scrollToIndexController = StreamController<int?>.broadcast();
  Stream<int?> get scrollToIndexStream => _scrollToIndexController.stream;

  final _unreadDividerIndexController = StreamController<int?>.broadcast();
  Stream<int?> get unreadDividerIndexStream => _unreadDividerIndexController.stream;  

  // 초기 로드가 완료되었음을 알리는 Completer (UI에서 대기할 수 있도록)
  final _initialLoadCompleter = Completer<void>();
  Future<void> get initialLoadDone => _initialLoadCompleter.future;

  // CarpoolRoomDetail을 직접 참조할 수 있도록 추가 (Provider를 통해 Watch)
  CarpoolRoomDetail? _currentRoomDetail;
  int? get driverId => _currentRoomDetail?.room.driver.id;

  ChatViewModel({
    required this.roomId,
    required ChatRepository repository,
    required CarpoolRepository carpoolRepository,
    required this.ref,
  }) : _repository = repository,
       _carpoolRepository = carpoolRepository,
       super([]) {

    _repository.setRoomId(roomId);

    final loginState = ref.watch(loginViewModelProvider);
    currentUserId = loginState.user?.id;

    _repository.setSenderId(currentUserId!);

    _loadMembersMap().then((_) {
      _currentRoomDetail = ref.read(chatRoomDetailProvider(roomId));
      _init().then((_) {
        if (!_initialLoadCompleter.isCompleted) {
          _initialLoadCompleter.complete();
        }
        print('[ChatViewModel] _init 완료');
        // _init 완료 후, 상태에 따라 스크롤 위치 지정
        _determineInitialScrollPosition();
      }).catchError((e) {
        if (!_initialLoadCompleter.isCompleted) {
          _initialLoadCompleter.completeError(e);
        }
        print('[ChatViewModel] _init 실패: $e');
      });
    }).catchError((e) {
      print('[ChatViewModel] _loadMembersMap 실패: $e');
      // 멤버 맵 로드 실패 시에도 초기 로드 완료 처리 (UI가 무한 대기하지 않도록)
      if (!_initialLoadCompleter.isCompleted) {
        _initialLoadCompleter.completeError(e);
      }
    });

    _repository.registerListener(_onReceived);

    ref.onDispose(() async {
      final currentStateSnapshot = List.of(state);
      await _saveRecentMessagesToPrefs(currentStateSnapshot);
      print('[ChatViewModel][ref.onDispose] Prefs - state 저장 완료');
    });
  }

  // 카풀 멤버 정보를 불러와 _membersMap을 초기화하고, CarpoolRoomDetail을 저장하는 메서드
  Future<void> _loadMembersMap() async {
    try {
      final roomDetail = await _carpoolRepository.fetchCarpoolDetails(roomId);
      ref.read(chatRoomDetailProvider(roomId).notifier).state = roomDetail;
      _membersMap[roomDetail.room.driver.id] = roomDetail.room.driver.name;
      for (var member in roomDetail.members) {
        _membersMap[member.userId] = member.name;
      }
      print('[ChatViewModel][_loadMembersMap] 멤버 맵 및 CarpoolRoomDetail 로드 완료: $_membersMap');
    } catch (e) {
      print('[ChatViewModel][_loadMembersMap] 멤버 맵 로드 실패: $e');
    }
  }

  // 초기 메세지 로드 및 처리
  Future<void> _init() async {
    List<ChatItem> allRawMessages = [];

    _isCacheEmptyOnInitialLoad = false; // 초기화
    _hasUnreadMessagesDivider = false; // 초기화

    try {
      // 1. 로컬(shared_preferences)에 저장된 메세지 로드
      final cached = await _loadMessagesFromPrefs();

      // 1-1. 로컬에 저장된 메세지 없음(모든 메세지 불러오기)
      if (cached.isEmpty) {
        print('[ChatViewModel][_init] 로컬에 저장된 메세지 없음 -> 모든 메세지 다 불러오기 시작');

        _isCacheEmptyOnInitialLoad = true;

        bool hasMore = true;
        Chat? lastMessage;

        while (hasMore) {
          final bool requestAll = lastMessage == null;  // 처음 한 번은 true
          final newMessages = await _repository.requestUnreadMessage(lastMessage, requestAll);
          if (newMessages == null || newMessages.isEmpty) {
            print('[ChatViewModel][_init] 모든 메세지 불러오기 - 불러온 메세지 없음 => ${allRawMessages.length}개');
            hasMore = false;
          } else {
            allRawMessages.addAll(newMessages.map((chat) => ChatMessageItem(chat: chat, status: ChatStatus.success, senderName: _membersMap[chat.senderId] ?? '알 수 없음',)));
            print('[ChatViewModel][_init] 모든 메세지 50개씩 불러오는 중-allRawMessages => ${allRawMessages.length}개');
            
            if (newMessages.length < 50) {
              hasMore = false;
            } else {
              lastMessage = newMessages.last;
            }
          }
        }
        print('[ChatViewModel][_init] 모든 메세지 불러옴-allRawMessages => ${allRawMessages.length}개');
        if (allRawMessages.isNotEmpty) {
          _scrollToIndexController.add(0); // 0번째 인덱스(가장 오래된 메시지)로 스크롤
          print('[ChatViewModel][_init] 캐시 비어있음: 인읽은 메세지의 맨 위로 스크롤 지시');
        }
      
      } else {

      // 1-2. 로컬에 저장된 메세지 있음(안읽은 메세지 불러오기)
        print('[ChatViewModel][_init] 로컬에 저장된 메세지 => ${cached.length}개');

        final updatedCached = cached.map((item) {
          // loading 또는 failed 상태면 failed로 설정
          final updatedStatus = (item.status == ChatStatus.success || item.status == ChatStatus.deleted)
            ? item.status
            : ChatStatus.failed;

          return ChatMessageItem(
            chat: item.chat,
            status: updatedStatus,
            senderName: _membersMap[item.chat.senderId] ?? '알 수 없음',
          );
        }).toList();

        allRawMessages.addAll(updatedCached);
        print('[ChatViewModel][_init] allRawMessages((1)로컬 메세지 추가) => ${allRawMessages.length}개');

        Chat currentRecentChat = updatedCached.last.chat;
        print('[ChatViewModel][_init] 로컬에 저장된 메세지(recentChat) : ${currentRecentChat.message}, timestamp: ${currentRecentChat.timestamp}');

        // 안읽은 메세지 불러오기(recentChat 기준)
        final unreadResponse = await _repository.requestUnreadMessage(currentRecentChat, false);      
        
        // 내가 보낸 메세지 필터링
        final filteredUnread = unreadResponse?.where((msg) => msg.senderId != currentUserId).toList() ?? [];
        
        print('[ChatViewModel][_init] 안읽은 메세지(필터링 전) => ${unreadResponse?.length}개');
        print('[ChatViewModel][_init] 안읽은 메세지(필터링 후) => ${filteredUnread?.length}개');

        // 안읽은 메세지 allRawMessages에 담기
        if (filteredUnread != null && filteredUnread.isNotEmpty) {
          _hasUnreadMessagesDivider = true;
          
          final unreadDividerTimestamp = currentRecentChat.timestamp.add(Duration(microseconds: 1));
          allRawMessages.add(UnreadDividerItem(timestamp: unreadDividerTimestamp));
          print('[ChatViewModel][_init] "안읽은 메시지 구분선" 추가');

          List<Chat> fetchedUnreadMessages = [];
          fetchedUnreadMessages.addAll(filteredUnread);
          currentRecentChat = filteredUnread.last;

          // 안읽은 메세지 전부 불러올 때까지 반복
          while (unreadResponse != null && unreadResponse.length == 50) { 
            final unreadResponse = await _repository.requestUnreadMessage(currentRecentChat, false);
            if (unreadResponse == null || unreadResponse.isEmpty) {
              break;
            }
            fetchedUnreadMessages.addAll(unreadResponse);
            currentRecentChat = unreadResponse.last;
            if (unreadResponse.length < 50) {
              break; // 50개 미만이면 더 이상 메시지 없음
            }
          }
          allRawMessages.addAll(fetchedUnreadMessages.map((chat) => ChatMessageItem(chat: chat, status: ChatStatus.success, senderName: _membersMap[chat.senderId] ?? '알 수 없음',)));
        } else {
          print('[ChatViewModel][_init] 안읽은 메세지 없음. 구분선 스킵.');
        }
      }

      print('[ChatViewModel][_init] 초기 allRawMessages 총 개수 (구분선 포함) => ${allRawMessages.length}개');

      // 정렬 및 날짜 구분선 추가해서 state 업데이트
      _updateStateWithDividers(allRawMessages);

      final socketManager = SocketManager();
      final IO.Socket socket = socketManager.getSocket();

      socket.off('reconnect');
      socket.on('reconnect', requestUnreadHandler);      

    } catch (e) {
      print('[ChatViewModel][_init] 초기 메세지 불러오기 실패: $e');
    }
  }

  // 로컬(Prefs)에 저장된 최근 50개 메세지 불러오기
  Future<List<ChatMessageItem>> _loadMessagesFromPrefs() async {
   final prefs = await SharedPreferences.getInstance();
    if (currentUserId == null) {
      print('[ChatViewModel][_loadMessagesFromPrefs] currentUserId가 null이므로 캐시 로드 스킵');
      return [];
    }
    final cacheKey = 'chat_cache_${currentUserId}_$roomId';
    try {
      final raw = prefs.getString(cacheKey);
      if (raw == null) {
        print('[ChatViewModel][_loadMessagesFromPrefs] 저장된 메시지 없음 (키: $cacheKey)');
        return [];
      }
      final List decoded = jsonDecode(raw);
      print('[ChatViewModel][_loadMessagesFromPrefs] ${decoded.length}개의 메시지 디코딩 완료');
      final loadedChatItems = <ChatMessageItem>[];
      for (final e in decoded) {
        try {
          final chat = Chat.fromJson(e['chat']);
          final statusString = e['status'] as String? ?? ChatStatus.success.name; // 'status' 키에서 String 읽기, null이면 기본값
          final status = ChatStatus.values.firstWhere(
            (s) => s.name == statusString,
            orElse: () => ChatStatus.success, // 일치하는 enum 값 없으면 success
          );
          final senderName = e['senderName'] as String ?? '';
          loadedChatItems.add(ChatMessageItem(chat: chat, status: status, senderName: senderName));
        } catch (e) {
          print('[ChatViewModel][_loadMessagesFromPrefs] 개별 메시지 파싱 오류: $e');
        }
      }
      return loadedChatItems;
    } catch (e) {
      print('[ChatViewModel][_loadMessagesFromPrefs] 메시지 디코딩 중 오류 발생: $e');
      return [];
    }
  }

  // 최근 메세지 50개 Prefs에 저장하기
  Future<void> _saveRecentMessagesToPrefs(List<ChatItem> chatItemsToSave) async {
    final prefs = await SharedPreferences.getInstance();
    if (currentUserId == null) {
      print('[ChatViewModel][_saveRecentMessagesToPrefs] currentUserId가 null이므로 캐시 저장 스킵');
      return;
    }
    final cacheKey = 'chat_cache_${currentUserId}_$roomId';
    final lastChat50 = chatItemsToSave.whereType<ChatMessageItem>().toList();
    final messagesToProcess = lastChat50.length <= 50 ? lastChat50 : lastChat50.sublist(lastChat50.length - 50);
    print('[ChatViewModel][_saveRecentMessagesToPrefs] 저장될 마지막 메세지: ${messagesToProcess.isEmpty ? "없음" : messagesToProcess.last.chat.message}');
    
    final jsonList = messagesToProcess.map((item) => {
      'chat': item.chat.toJson(),
      'status': item.status.name,
      'senderName': item.senderName,
    }).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(cacheKey, jsonString);
    print('[ChatViewModel][_saveRecentMessagesToPrefs] ${messagesToProcess.length}개의 메시지 저장 완료');
  }

  // 실시간 메세지 수신
  void _onReceived(Chat chat) {
    print('[ChatViewModel][_onReceived] 메시지 수신: ${chat.message} (senderId=${chat.senderId}, timestamp=${chat.timestamp})');

    // 현재 ChatMessageItem 목록만 추출 (구분선들은 배제)
    final List<ChatMessageItem> currentChatMessages = state.whereType<ChatMessageItem>().toList();
    final newChatMessageItem = ChatMessageItem(chat: chat, status: ChatStatus.success, senderName: _membersMap[chat.senderId] ?? '알 수 없음',);

    // 모든 ChatMessageItem을 합쳐서 _updateStateWithDividers로 전달
    final List<ChatItem> combinedRawItems = [...currentChatMessages, newChatMessageItem];
    _updateStateWithDividers(combinedRawItems); // 이 함수가 정렬과 구분선 추가 모두 처리

    print('[ChatViewModel][_onReceived] state 업데이트 완료, 새 메시지 수신. state => 총 ${state.length}개');
    
    // 새 메세지 수신하면 무조건 맨 아래로 스크롤
    _scrollToBottomController.add(null);
  }

  // 전송하려는 텍스트 -> Chat 생성
  Future<void> sendMessage(String message) async {
    if (currentUserId == null) return;

    final chat = Chat(
      senderId: currentUserId!,
      roomId: roomId,
      message: message,
      timestamp: DateTime.now(),
    );
    await sendChat(chat);
  }

  // sendChat : Chat 받아서 전송
  Future<void> sendChat(Chat chat) async {

    if (currentUserId == null) return;
    final loginState = ref.read(loginViewModelProvider);

    final sendingChatItem = ChatMessageItem(chat: chat, status: ChatStatus.loading, senderName: _membersMap[currentUserId!] ?? loginState.user?.name ?? '',);

    // 현재 ChatMessageItem 목록만 추출하여 로딩 메시지 추가
    final List<ChatMessageItem> currentChatMessages = state.whereType<ChatMessageItem>().toList();
    final List<ChatItem> rawItemsWithLoading = [...currentChatMessages, sendingChatItem];
    _updateStateWithDividers(rawItemsWithLoading); // UI에 로딩 메시지 표시

    _scrollToBottomController.add(null); // 로딩 메시지 추가 후 바로 스크롤

    // ❶ 타임아웃 타이머 시작
    Timer? failTimer = Timer(const Duration(seconds: 10), () {
      final ChatMessageItem? loadingMsg = state.whereType<ChatMessageItem>().firstWhereOrNull(
        (item) =>
            item.status == ChatStatus.loading &&
            item.chat.timestamp == chat.timestamp &&
            item.chat.senderId == chat.senderId &&
            item.chat.message == chat.message,
      );
      if (loadingMsg != null) {
        print('[ChatViewModel][sendChat] 5초 경과, 실패 처리: ${chat.message}');
        final updated = state.map((item) {
          if (item is ChatMessageItem &&
              item.status == ChatStatus.loading &&
              item.chat.timestamp == chat.timestamp &&
              item.chat.senderId == chat.senderId &&
              item.chat.message == chat.message) {
            return ChatMessageItem(
              chat: item.chat,
              status: ChatStatus.failed,
              senderName: item.senderName,
            );
          }
          return item;
        }).toList();
        _updateStateWithDividers(updated);
      }
    });

    // ❷ 실제 전송
    final sent = await _repository.sendChat(chat);

    // ❸ 성공 시 타이머 취소 + 상태 업데이트
    if (sent != null) {
      failTimer.cancel(); // 이미 성공했으면 실패 타이머 중지

      print('[ChatViewModel][sendChat] 메시지 전송 성공: ${sent.message}');

      final updated = state.map((item) {
        if (item is ChatMessageItem &&
            item.status == ChatStatus.loading &&
            item.chat.timestamp == chat.timestamp &&
            item.chat.senderId == chat.senderId &&
            item.chat.message == chat.message) {
          return ChatMessageItem(
            chat: sent,
            status: ChatStatus.success,
            senderName: _membersMap[sent.senderId] ?? '알 수 없음',
          );
        }
        return item;
        }).toList();
      _updateStateWithDividers(updated);
    }
  }

  // 재전송
  Future<void> retryMessage(Chat chat) async {

    // 실패 메시지 삭제
    final updated = state.where((item) {
      if (item is ChatMessageItem &&
          item.status == ChatStatus.failed &&
          item.chat.timestamp == chat.timestamp &&
          item.chat.senderId == chat.senderId &&
          item.chat.message == chat.message) {
        return false;
      }
      return true;
    }).toList();

    _updateStateWithDividers(updated);

    // 상태 업데이트 후 약간의 딜레이를 주어 UI 갱신 대기 (필요 시)
    await Future.delayed(Duration(milliseconds: 50));

    // 재전송 호출 (비동기 처리 분리)
    await _sendChatWithoutFiltering(chat);
  }

  Future<void> _sendChatWithoutFiltering(Chat chat) async {
    if (currentUserId == null) return;
    final loginState = ref.read(loginViewModelProvider);

    // 현재 상태 메시지 리스트 그대로 사용 (필터링 없음)
    final List<ChatMessageItem> currentChatMessages = state.whereType<ChatMessageItem>().toList();

    // 로딩 메시지 추가
    final sendingChatItem = ChatMessageItem(
      chat: chat,
      status: ChatStatus.loading,
      senderName: _membersMap[currentUserId!] ?? loginState.user?.name ?? '',
    );

    final List<ChatItem> rawItemsWithLoading = [...currentChatMessages, sendingChatItem];
    _updateStateWithDividers(rawItemsWithLoading);

    _scrollToBottomController.add(null); // 스크롤

    final sent = await _repository.sendChat(chat);

    // 전송 결과 반영
    final List<ChatMessageItem> updatedMessages = state.whereType<ChatMessageItem>().map((item) {
      if (item.status == ChatStatus.loading &&
          item.chat.timestamp == chat.timestamp &&
          item.chat.senderId == chat.senderId &&
          item.chat.message == chat.message) {
        if (sent == null) {
          print('[ChatViewModel][_sendChatWithoutFiltering] 메시지 전송 실패: ${chat.message}');
          return ChatMessageItem(
            chat: chat,
            status: ChatStatus.failed,
            senderName: _membersMap[chat.senderId] ?? '알 수 없음',
          );
        } else {
          print('[ChatViewModel][_sendChatWithoutFiltering] 메시지 전송 성공: ${sent.message}');
          return ChatMessageItem(
            chat: sent,
            status: ChatStatus.success,
            senderName: _membersMap[sent.senderId] ?? '알 수 없음',
          );
        }
      }
      return item;
    }).toList();

    _updateStateWithDividers(updatedMessages);
  }

  // 삭제
  void deleteFailedMessage(Chat chat) {
    final updated = state.where((item) {
      if (item is ChatMessageItem &&
          item.status == ChatStatus.failed &&
          item.chat.timestamp == chat.timestamp &&
          item.chat.senderId == chat.senderId &&
          item.chat.message == chat.message) {
        return false; // 삭제
      }
      return true;
    }).toList();

    _updateStateWithDividers(updated);
  }

  /// 위로 스크롤 시 이전 메시지 로드
  Future<void> loadPreviousMessages() async {
    print('[DEBUG][loadPreviousMessages] State content at the beginning of function:');

    // 더 이상 불러올 '이전' 메시지가 없거나, 이미 로드 중이거나, 현재 메시지가 없으면 스킵
    if (!_hasMorePreviousMessages || _isLoadingPreviousMessages || state.isEmpty) {
      print('[ChatViewModel][loadPreviousMessages] 스킵: hasMorePreviousMessages=$_hasMorePreviousMessages, isLoadingPreviousMessages=$_isLoadingPreviousMessages, state.isEmpty=${state.isEmpty}');
      return;
    }

    _isLoadingPreviousMessages = true;

    try {
      // 현재 state에서 가장 오래된 ChatMessageItem 찾기 (firstOrNull 사용)
      final firstMessageItem = state.whereType<ChatMessageItem>().firstOrNull;

      print('[ChatViewModel][loadPreviousMessages] firstMessageItem: ${firstMessageItem?.chat.message}');

      if (firstMessageItem == null) {
        print('[ChatViewModel][loadPreviousMessages] ChatMessageItem을 찾을 수 없음');
        _isLoadingPreviousMessages = false;
        return;
      }

      Chat oldestChat = firstMessageItem.chat;
      print('[ChatViewModel][loadPreviousMessages] oldestChat (기준 메시지): ${oldestChat.message}, timestamp: ${oldestChat.timestamp}');

      final DateTime utcTimestamp = oldestChat.timestamp.toUtc();
      final previousMessages = await _repository.loadChats(oldestChat.copyWith(timestamp: utcTimestamp),);
      print('[ChatViewModel][loadPreviousMessages] 서버 요청 기준 timestamp(UTC): ${utcTimestamp.toIso8601String()}');

      if (previousMessages != null && previousMessages.isNotEmpty) {
        print('[ChatViewModel][loadPreviousMessages] 서버에서 로드된 이전 메시지 (ID): ${previousMessages.map((chat) => chat.message).join(', ')}');
        print('[DEBUG] 🔄 previousMessages 로드됨: ${previousMessages.length}개');

        final first = previousMessages.first;
        final last = previousMessages.last;

        print('[DEBUG] ⏪ 첫 메시지: msg=${first.message}, ts=${first.timestamp.toIso8601String()}');
        print('[DEBUG] ⏩ 마지막 메시지: msg=${last.message}, ts=${last.timestamp.toIso8601String()}');

        // 중복 메시지 필터링 (message + timestamp 기준)
        final existingKeys = state
            .whereType<ChatMessageItem>()
            .map((item) => '${item.chat.message}_${item.chat.timestamp.toIso8601String()}')
            .toSet();

        final previousChatItems = previousMessages
            .where((chat) =>
                !existingKeys.contains('${chat.message}_${chat.timestamp.toIso8601String()}'))
            .map((chat) => ChatMessageItem(chat: chat, status: ChatStatus.success, senderName: _membersMap[chat.senderId] ?? '알 수 없음',))
            .toList();

        // 새로 로드된 메시지 개수가 50개 미만이면 더 이상 이전 메시지가 없는 것으로 판단
        if (previousChatItems.length < 50) {
          _hasMorePreviousMessages = false;
          print('[ChatViewModel][loadPreviousMessages] 더 이상 불러올 메시지가 없습니다 (로드된 개수: ${previousChatItems.length})');
        } else {
          _hasMorePreviousMessages = true; // 50개를 채웠으니 더 있을 가능성 있음
          oldestChat = previousChatItems.first.chat;
          print('oldestChat = $oldestChat');
        }

        // 현재 state의 ChatMessageItem만 추출
        final List<ChatMessageItem> currentChatMessages = state.whereType<ChatMessageItem>().toList();
        print('currentChatMessages.first = ${currentChatMessages.first}');

        // 새로 로드된 이전 메시지와 현재 메시지를 합침
        final List<ChatItem> combinedRawItems = [
            ...previousChatItems,
            ...currentChatMessages,
        ];

        // _updateStateWithDividers에 전달하여 정렬 및 구분선 삽입
        _updateStateWithDividers(combinedRawItems);
        print('[ChatViewModel][loadPreviousMessages] 서버에서 이전 메시지 ${previousChatItems.length}개 로드 및 추가');

      } else {
        _hasMorePreviousMessages = false;
        print('[ChatViewModel][loadPreviousMessages] 서버에 더 이상 이전 메시지가 없음');
      }
    } catch (e) {
      print('[ChatViewModel][loadPreviousMessages] 이전 메시지 로드 실패: $e');
    } finally {
      _isLoadingPreviousMessages = false;
    }
  }

  // 정렬 후 날짜, 안읽은 메세지 구분선 추가해서 state 업데이트하기
  Future<void> _updateStateWithDividers(List<ChatItem> rawChatItems) async {
    print('[ChatViewModel][_updateStateWithDividers] rawChatItems count: ${rawChatItems.length}개');

    if (rawChatItems.isEmpty) {
      state = [];
      print('[ChatViewModel][_updateStateWithDividers] rawChatItems가 비어있어 상태 업데이트 스킵.');
      return;
    }

    final List<ChatItem> finalItems = [];
    DateTime? previousMessageDate; // 이전 ChatMessageItem의 날짜만 추적
    bool unreadDividerJustAdded = false; // UnreadDividerItem이 방금 추가되었는지 여부 플래그

    final ChatMessageItem? firstChatMessage = rawChatItems
      .firstWhereOrNull((item) => item is ChatMessageItem) as ChatMessageItem?; // firstWhereOrNull 사용 

    if (firstChatMessage != null) {
      if (firstChatMessage.chat != null && firstChatMessage.chat!.timestamp != null) { // timestamp도 null 체크
        previousMessageDate = DateUtils.dateOnly(firstChatMessage.chat!.timestamp!);
        finalItems.add(DateDividerItem(date: previousMessageDate!));
      } else {
        // chat이 null인 경우에 대한 처리 (예: 첫 날짜 구분선 추가 스킵)
        print('[DEBUG] 첫 ChatMessageItem의 chat 필드가 null.');
      }
    }

    // 모든 ChatItem (ChatMessageItem, UnreadDividerItem)을 timestamp 기준으로 정렬
    final List<ChatItem> sortedAllItems = rawChatItems
        .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final ChatItem item in sortedAllItems) {
      if (item is UnreadDividerItem) {
        finalItems.add(item);
        unreadDividerJustAdded = true; // UnreadDividerItem이 추가되었음을 표시
      } else if (item is ChatMessageItem) {
        final DateTime messageDate = DateTime(
          item.chat.timestamp.year,
          item.chat.timestamp.month,
          item.chat.timestamp.day,
        );
        
        bool shouldAddDateDivider = false;

        if (previousMessageDate == null || messageDate.difference(previousMessageDate!).inDays != 0) {
          shouldAddDateDivider = true;
        }
        if (unreadDividerJustAdded && previousMessageDate != null && messageDate.difference(previousMessageDate!).inDays == 0) {
            shouldAddDateDivider = false;
        }
        if (shouldAddDateDivider) {
          finalItems.add(DateDividerItem(date: messageDate));
        }

        finalItems.add(item);
        previousMessageDate = messageDate;
        unreadDividerJustAdded = false;
      }
    }

    state = finalItems; // 최종 상태 업데이트
    print('[ChatViewModel][_updateStateWithDividers] Final state updated. Total ${state.length} items.');
  }

  // _updateDateDivider(onReceived, sendChat에 쓰려고 했는데 보류)
  Future<void> _updateDateDivider(Chat newChat) async {

    print('[ChatViewModel][_updateDateDivider]');
    
    List<ChatItem> currentItems = List.from(state);

    DateTime newDate = DateTime(newChat.timestamp.year,
                                  newChat.timestamp.month,
                                  newChat.timestamp.day);

    if (currentItems.isEmpty) {
      currentItems.add(DateDividerItem(date: newDate));
      currentItems.add(ChatMessageItem(chat: newChat, status: ChatStatus.success, senderName: _membersMap[newChat.senderId] ?? '알 수 없음',));
    } else {
      ChatItem lastChatItem = currentItems.last;
      
      // state의 마지막 메세지 날짜와 새로운 메세지 날짜 비교하여 날짜 구분선 추가
      if (lastChatItem.type == ChatItemType.message) {
        final ChatMessageItem lastChatMessageItem = lastChatItem as ChatMessageItem;
        DateTime lastDate = DateTime(lastChatMessageItem.chat.timestamp.year,
                                    lastChatMessageItem.chat.timestamp.month,
                                    lastChatMessageItem.chat.timestamp.day);

        // 날짜가 변경되었는지 확인
        if (newDate.day != lastDate.day ||
            newDate.month != lastDate.month ||
            newDate.year != lastDate.year) {
          print('[ChatViewModel][_updateDateDivider] 날짜 변경 감지. 날짜 구분선 추가.');
          currentItems.add(DateDividerItem(date: newDate));
        }
      currentItems.add(ChatMessageItem(chat: newChat, status: ChatStatus.success, senderName: _membersMap[newChat.senderId] ?? '알 수 없음'));
      } 
    }
    state = currentItems;
    print('[ChatViewModel][_updateDateDivider] 메시지 추가 및 상태 업데이트. 총 ${state.length}개.');
  }
  
  // 로컬 캐시 지우기 위한 테스트 코드 (MyApp 확인)
  Future<void> deleteChatMessagesForRoom(int userId, int roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'chat_cache_${userId}_$roomId';
    await prefs.remove(cacheKey);
    print('[SharedPreferencesManager] 채팅방 $roomId (사용자 $userId)의 로컬 캐시 메시지 삭제 완료: $cacheKey');
  }

  // 초기 스크롤 위치를 결정하고 UI에 신호 보내기
  void _determineInitialScrollPosition() {
    if (state.isEmpty) {
      return;
    }

    if (_isCacheEmptyOnInitialLoad) {
      // 1. 로컬 캐시가 없었으면 맨 위로 (모든 메시지를 새로 불러왔을 때)
      print('[ChatViewModel][_determineInitialScrollPosition] 캐시 없음, 맨 위로 스크롤 지시');
      _scrollToIndexController.add(0); // 인덱스 0 (맨 위)
    } else if (_hasUnreadMessagesDivider) {
      // 2. 로컬 캐시 있었는데 안 읽은 구분선 있으면 구분선으로
      final unreadDividerIndex = state.indexWhere((item) => item is UnreadDividerItem);
      if (unreadDividerIndex != -1) {
        print('[ChatViewModel][_determineInitialScrollPosition] 캐시 있음 & 구분선 있음, ${unreadDividerIndex}번 인덱스로 스크롤 지시');
        _scrollToIndexController.add(unreadDividerIndex);
      } else {
        print('[ChatViewModel][_determineInitialScrollPosition] 오류: 구분선 플래그는 true인데 인덱스 찾을 수 없음. 맨 아래로 스크롤.');
        _scrollToIndexController.add(null);
      }
    } else {
      // 3. 로컬 캐시 있었는데 안 읽은 구분선 없으면 맨 하단으로
      print('[ChatViewModel][_determineInitialScrollPosition] 캐시 있음 & 구분선 없음, 맨 아래로 스크롤 지시');
      _scrollToIndexController.add(null); // null (맨 아래)
    }
  }

  // 소켓 재연결 됐을 때 메시지 불러오기
  Future<void> requestUnreadHandler(dynamic payload) async {
    assert(() {
      print('[ChatViewModel][_onSocketReconnect] 소켓 재연결 감지! 미확인 메시지 로드를 시도.');
      return true;
    }());

    final ChatMessageItem? lastMessageItem = state.whereType<ChatMessageItem>().lastOrNull;

    final bool requestAll = lastMessageItem == null;
    Chat? lastChat = lastMessageItem?.chat;

    try {
      final List<Chat>? newMessagesFromServer = await _repository.requestUnreadMessage(lastChat, requestAll);

      if (newMessagesFromServer != null && newMessagesFromServer.isNotEmpty) {
        assert(() {
          print('[ChatViewModel][_onSocketReconnect] 서버로부터 새로운 미확인 메시지 ${newMessagesFromServer.length}개 수신.');
          return true;
        }());

        // 1. 현재 ViewModel의 모든 ChatMessageItem을 가져오기
        final List<ChatMessageItem> existingChatMessages = state.whereType<ChatMessageItem>().toList();

        // 2. 새로운 ChatMessageItem (최종 업데이트될 메시지들)을 담을 리스트 준비
        // 초기에는 기존 메시지들을 모두 포함
        Map<String, ChatMessageItem> updatedMessageMap = {
          for (var item in existingChatMessages) _getMessageKey(item.chat): item
        };

        // 3. 서버에서 받은 newMessagesFromServer를 처리
        for (var serverChat in newMessagesFromServer) {
          final String serverMessageKey = _getMessageKey(serverChat);

          // 서버 메시지에 대한 ChatMessageItem을 성공 상태로 생성
          final ChatMessageItem serverReceivedItem = ChatMessageItem(
            chat: serverChat,
            status: ChatStatus.success, // 서버에서 받은 메시지는 성공으로 처리
            senderName: _membersMap[serverChat.senderId] ?? '알 수 없음',
          );

          // 만약 기존 메시지 목록에 동일한 키의 메시지가 있다면
          if (updatedMessageMap.containsKey(serverMessageKey)) {
            final existingItem = updatedMessageMap[serverMessageKey]!;
            // 기존 메시지가 loading 또는 failed 상태였다면, 서버에서 받은 성공 상태로 업데이트
            if (existingItem.status == ChatStatus.loading || existingItem.status == ChatStatus.failed) {
              assert(() {
                print('[ChatViewModel][_onSocketReconnect] 기존 failed/loading 메시지 (${existingItem.chat.message}) -> success로 업데이트.');
                return true;
              }());
              updatedMessageMap[serverMessageKey] = serverReceivedItem; // 성공 상태로 교체
            }
            // 기존 메시지가 이미 success였다면 (또는 deleted), 무시 (중복 추가 방지)
          } else {
            // 기존 메시지 목록에 없는 완전히 새로운 메시지라면 추가
            assert(() {
              print('[ChatViewModel][_onSocketReconnect] 완전히 새로운 미확인 메시지 추가: ${serverChat.message}');
              return true;
            }());
            updatedMessageMap[serverMessageKey] = serverReceivedItem;
          }
        }

        // 4. Map의 values를 리스트로 변환하여 _updateStateWithDividers에 전달합니다.
        final List<ChatItem> finalRawItems = updatedMessageMap.values.toList();
        _updateStateWithDividers(finalRawItems);

        _scrollToBottomController.add(null);
        assert(() {
          print('[ChatViewModel][_onSocketReconnect] 상태 업데이트 및 스크롤 지시 완료.');
          return true;
        }());
      } else {
        assert(() {
          print('[ChatViewModel][_onSocketReconnect] 서버로부터 새로운 미확인 메시지가 없습니다.');
          return true;
        }());
      }
    } catch (e) {
      assert(() {
        print('[ChatViewModel][_onSocketReconnect] 미확인 메시지 로드 중 오류 발생: $e');
        return true;
      }());
      // 오류 발생 시 사용자에게 알림을 줄 수 있는 로직 추가 (예: SnackBar)
    }
  }

  // 메시지의 고유 키를 생성하는 헬퍼 함수
  String _getMessageKey(Chat chat) {
    // 메시지 내용, 타임스탬프, senderId를 조합하여 고유한 키를 생성
    return '${chat.message}_${chat.timestamp.toIso8601String()}_${chat.senderId}';
  }

  @override
  void dispose() {
    _hasUnreadMessagesDivider = false;
    _repository.dispose();
    _scrollToBottomController.close();
    _scrollToIndexController.close();
    _unreadDividerIndexController.close();
    
    final socketManager = SocketManager();
    final IO.Socket socket = socketManager.getSocket();

    socket.off('reconnect', requestUnreadHandler);
    // socket.on('reconnect', );      

    super.dispose();
  }
}