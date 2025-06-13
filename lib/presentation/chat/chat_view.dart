import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/core/provider.dart';
import 'package:cba_connect_application/models/chat.dart';
import 'package:cba_connect_application/models/chat_item.dart';
import 'package:cba_connect_application/presentation/chat/chat_view_model.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';
import 'package:cba_connect_application/core/color.dart';
import 'package:intl/intl.dart';

class ChatView extends ConsumerStatefulWidget {
  final int roomId;
  final String name;
  const ChatView({super.key, required this.roomId, required this.name});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottomButton = false;
  int _lastKnownItemCount = 0;

  final double _inputFieldEstimatedHeight = 90.0;
  final double _chatItemEstimatedHeight = 60.0; 

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    final chatViewModel = ref.read(chatViewModelProvider(widget.roomId).notifier);

    // ViewModel에서 맨 위(0번 인덱스)로 스크롤하라는 신호가 올 때 처리
    chatViewModel.scrollToIndexStream.listen((index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        print('[ChatView] scrollToIndexStream: ScrollController clients 없음. 스크롤 지시 무시.');
        return;
      }

      if (index == 0) { // 맨 위로 스크롤 (캐시 없음 시)
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
        print('[ChatView] scrollToIndexStream: 맨 위(0번째 인덱스)로 점프 지시 받음');
      } else if (index != null && index >= 0 && index < chatViewModel.state.length) {
        // 특정 인덱스 (구분선)로 스크롤 지시
        final double offset = index * _chatItemEstimatedHeight; // <-- 인덱스에 대략적인 아이템 높이를 곱하여 오프셋 계산
        _scrollController.jumpTo(offset); // 계산된 오프셋으로 이동
        print('[ChatView] scrollToIndexStream: ${index}번 인덱스 아이템으로 대략적인 스크롤 지시 받음');
      } else if (index == null) { // null 지시 (맨 아래로 스크롤)
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        print('[ChatView] scrollToIndexStream: null 지시, 맨 아래로 점프 지시 받음');
      } else {
        print('[ChatView] scrollToIndexStream: 유효하지 않은 인덱스 또는 알 수 없는 지시: $index');
      }
    });
  });

    /*
    WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.delayed(Duration(milliseconds: 200)); // layout 반영 대기
    if (_scrollController.hasClients) {
      try {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } catch (e) {
        // 무시 가능한 스크롤 예외
      }
    }
  });
  */
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    // 키보드 숨기기
    FocusScope.of(context).unfocus();

    final double currentBottomPadding = _inputFieldEstimatedHeight + MediaQuery.of(context).viewInsets.bottom + 16;
    final bool isNearBottom = _scrollController.position.extentAfter < currentBottomPadding + 50;

    if (_showScrollToBottomButton == isNearBottom) {
      setState(() {
        _showScrollToBottomButton = !isNearBottom;
      });
    }

    // 스크롤이 맨 위로 도달했는지 확인 (또는 특정 임계값)
    if (_scrollController.position.pixels == _scrollController.position.minScrollExtent) {
      ref.read(chatViewModelProvider(widget.roomId).notifier).loadPreviousMessages();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);
    final currentUserId = loginState.user?.id;
    final userName = loginState.user?.name ?? "알 수 없음";

    if (currentUserId == null) {
      return const Center(child: Text("로그인 정보 없음"));
    }

    final chatItems = ref.watch(chatViewModelProvider(widget.roomId));
    final chatViewModel = ref.read(
      chatViewModelProvider(widget.roomId).notifier,
    );

    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    WidgetsBinding.instance.addPostFrameCallback((_) {
        if (chatItems.length > _lastKnownItemCount) {
            _handleNewMessageScroll(chatItems, keyboardHeight);
        }
        _lastKnownItemCount = chatItems.length;
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // 키보드 숨기기
      behavior: HitTestBehavior.opaque, // 빈 영역에서도 탭 감지
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          // title: Text("$userName's ${widget.roomId}번 카풀 단톡방"),
          title: Text('${widget.name}님의 카풀 메시지'),
          actions: const [
            Icon(Icons.person),
            SizedBox(width: 8),
            Center(child: Text("2/3")), // 📍 TODO : 실제 인원 수로 대체
            SizedBox(width: 12),
            IconButton(icon: Icon(Icons.call), onPressed: null),  // 📍 TODO : 통화 아이콘 클릭시 통화 연결 또는 연락처 복사
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: false,
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: chatItems.length,
                    itemBuilder: (context, index) {
                      final chatItem = chatItems[index];

                      if (chatItem is ChatMessageItem) {
                        final isMine = chatItem.chat.senderId == currentUserId;
                        return _buildMessageBubble(
                          chatItem.chat,
                          chatItem.status,
                          isMine,
                        );
                      } else if (chatItem is UnreadDividerItem) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: Colors.grey,
                                  thickness: 0.5,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  chatItem.text,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  color: Colors.grey,
                                  thickness: 0.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (chatItem is DateDividerItem) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[100],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              DateFormat('yyyy년 MM월 dd일').format(chatItem.date),
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                _buildInputField(chatViewModel),
              ],
            ),
            if (_showScrollToBottomButton)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: _inputFieldEstimatedHeight + keyboardHeight + 10),
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: secondarySub2Color,
                    onPressed: _scrollToBottom,
                    child: const Icon(Icons.arrow_downward),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleNewMessageScroll(List<ChatItem> chatItems, double keyboardHeight) async {
    await Future.delayed(Duration(milliseconds: 100));
    if (!_scrollController.hasClients) return;

    final double currentBottomPadding = _inputFieldEstimatedHeight + keyboardHeight + 16;
    final bool isNearBottom = _scrollController.position.extentAfter < currentBottomPadding + 30;

    if (isNearBottom) {
      _scrollToBottom();
    } else {
      if (!_showScrollToBottomButton) {
        setState(() {
          _showScrollToBottomButton = true;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.microtask(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ).then((_) {
            if (_showScrollToBottomButton) {
              setState(() {
                _showScrollToBottomButton = false;
              });
            }
          });
        }
      });
    });
  }

  Widget _buildMessageBubble(Chat message, ChatStatus status, bool isMine) {
    final timeText = _formatTime(message.timestamp);
    final senderName = isMine ? '' : '${message.senderId}';

    Widget timeWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(timeText, style: _timeStyle),
    );

    return Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (senderName.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isMine ? 0 : 8,
              right: isMine ? 8 : 0,
              bottom: isMine ? 0 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 16, color: text800Color),
                SizedBox(width: 4),
                Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 16,
                    color: text800Color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children:
                isMine
                    ? [timeWidget, _messageContainer(message.message, isMine)]
                    : [_messageContainer(message.message, isMine), timeWidget],
          ),
        ),
        if (status == ChatStatus.loading)
          Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              '전송 중...',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        if (status == ChatStatus.failed)
          Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              '전송 실패!',
              style: TextStyle(fontSize: 10, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _messageContainer(String text, bool isMine) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMine ? secondaryColor : Colors.grey.shade200,
        borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isMine ? 20 : 0),
        topRight: Radius.circular(isMine ? 0 : 20),
        bottomLeft: const Radius.circular(20),
        bottomRight: const Radius.circular(20),
        ),
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: isMine ? text200Color : text900Color,
        ),
      ),
    );
  }

  Widget _buildInputField(ChatViewModel chatViewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '메세지를 입력하세요.',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            GestureDetector(
              onTap: () {
                final text = _controller.text.trim();
                if (text.isEmpty) return;
                chatViewModel.sendMessage(text);
                _controller.clear();
                _scrollToBottom();
              },
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.send, color: secondaryColor, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
      
  final TextStyle _timeStyle = const TextStyle(
    fontSize: 12,
    color: text800Color,
  );

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? '오후' : '오전';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$period $hour12:$minute';
  }
}

class ChatDivider extends StatelessWidget {
  final String text;

  const ChatDivider({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 30, bottom: 10, left: 5, right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(color:secondaryColor, fontSize: 12),
        ),
      ),
    );
  }
}