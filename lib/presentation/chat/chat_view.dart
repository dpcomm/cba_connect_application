import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/core/provider.dart';
import 'package:cba_connect_application/models/chat.dart';
import 'package:cba_connect_application/presentation/chat/chat_view_model.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';
import 'package:cba_connect_application/core/color.dart';

class ChatView extends ConsumerStatefulWidget {
  final int roomId;
  const ChatView({super.key, required this.roomId});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);
    final currentUserId = loginState.user?.id;
    final userName = loginState.user?.name ?? "알 수 없음";

    if (currentUserId == null) {
      return const Center(child: Text("로그인 정보 없음"));
    }

    final roomSenderId = RoomSenderId(
      roomId: widget.roomId,
      senderId: currentUserId,
    );

    final chatMessages = ref.watch(chatViewModelProvider(roomSenderId));
    final chatViewModel = ref.read(
      chatViewModelProvider(roomSenderId).notifier,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: Text("$userName's ${widget.roomId}번 카풀 단톡방"),
        actions: const [
          Icon(Icons.person),
          SizedBox(width: 8),
          Center(child: Text("2/3")), // 실제 인원 수로 대체 필요
          SizedBox(width: 12),
          IconButton(icon: Icon(Icons.call), onPressed: null),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final message = chatMessages[index];
                final isMine = message.senderId == currentUserId;
                return _buildMessageBubble(message, isMine);
              },
            ),
          ),
          _buildInputField(chatViewModel),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Chat message, bool isMine) {
    final timeText = _formatTime(message.timestamp);

    Widget timeWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(timeText, style: _timeStyle),
    );

    return Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _messageContainer(String text, bool isMine) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMine ? secondaryColor : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
