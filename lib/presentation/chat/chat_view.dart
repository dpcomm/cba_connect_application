import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/core/provider.dart';
import 'package:cba_connect_application/models/chat.dart';
import 'package:cba_connect_application/models/chat_item.dart';
import 'package:cba_connect_application/presentation/chat/chat_view_model.dart';
import 'package:cba_connect_application/presentation/chat/chat_members_view_model.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/presentation/chat/chat_report_view.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';
import 'package:cba_connect_application/core/color.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // 전화 걸기 기능 추가

class ChatView extends ConsumerStatefulWidget {
  final int roomId;
  const ChatView({super.key, required this.roomId});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _textController = TextEditingController();
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

  // 전화 걸기 함수
  Future<void> _makePhoneCall(String phone) async {
    print('[ChatView][_makePhoneCall] 시도 전화번호: $phone');

    // 전화번호가 비어있는지 다시 한번 확인
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호가 유효하지 않습니다.')),
      );
      print('[ChatView][_makePhoneCall] 전화번호가 비어있습니다.');
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final bool canLaunch = await canLaunchUrl(launchUri);
      print('[ChatView][_makePhoneCall] canLaunchUrl 결과: $canLaunch');

      if (canLaunch) {
        await launchUrl(launchUri);
        print('[ChatView][_makePhoneCall] 전화 걸기 성공!');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전화를 걸 수 없습니다.')),
        );
        print('[ChatView][_makePhoneCall] canLaunchUrl이 false를 반환했습니다.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전화 걸기 중 오류 발생: $e')),
      );
      print('[ChatView][_makePhoneCall] 전화 걸기 중 예외 발생: $e'); // 예외 로그 추가
    }
  }

  void _showMembersPopup(BuildContext context, int roomId, int currentUserId) {
    final carpoolDetail = ref.read(chatRoomDetailProvider(roomId));
    final int? driverId = carpoolDetail?.room.driver.id;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Center(child: Text('카풀 참여자')),
          content: Consumer(
            builder: (context, ref, _) {

              final membersAsyncValue = ref.watch(carpoolMembersProvider(roomId));

              return membersAsyncValue.when(
                data: (members) {
                  final List<CarpoolUserInfo> sortedMembers = List.from(members);
                  final int driverIndex = sortedMembers.indexWhere((member) => member.userId == driverId);

                  if (driverIndex != -1) {
                    final CarpoolUserInfo driver = sortedMembers.removeAt(driverIndex);
                    sortedMembers.insert(0, driver); // 운전자를 맨 위로
                  }

                  if (sortedMembers.isEmpty) {
                    return const Center(child: Text('참여 멤버가 없습니다.'));
                  }

                  return SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: sortedMembers.length,
                      itemBuilder: (context, index) {
                        final member = sortedMembers[index];
                        final isMe = member.userId == currentUserId;
                        final isDriver = member.userId == driverId;

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isDriver ? Icons.directions_car : Icons.person,
                          ),
                          title: Text(member.name + (isMe ? '(나)' : '')),
                          trailing: isMe
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        backgroundColor: secondarySub2Color.withOpacity(0.1),
                                      ),
                                      onPressed: member.phone.isNotEmpty
                                          ? () => _makePhoneCall(member.phone)
                                          : null,
                                      child: Row(
                                        children: [
                                          Icon(Icons.call, size: 20),
                                          SizedBox(width: 2),
                                          Text('통화'),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        backgroundColor: Colors.red.withOpacity(0.07),
                                        foregroundColor: Colors.red,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _goToReportPage(context, roomId, member.userId, member.name);
                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.report, size: 20),
                                          SizedBox(width: 2),
                                          Text('신고'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
                  );
                },
                loading: () {
                  return const Center(child: CircularProgressIndicator());
                },
                error: (error, stackTrace) {
                  print('Error loading members in popup: $error');
                  return Center(child: Text('멤버 정보를 불러올 수 없습니다.\n오류: ${error.toString().split(':')[0]}', textAlign: TextAlign.center));
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  void _goToReportPage(BuildContext context, int roomId, int reportedUserId, String reportedUserName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatReportView(
          roomId: roomId,
          reportedUserId: reportedUserId,
          reportedUserName: reportedUserName,
        ),
      ),
    );
  }

  void _showCarpoolInfo(BuildContext context, CarpoolRoomDetail? detail) {
    if (detail == null) return;

    // 수련회장 주소
    const retreatAddress = '경기도 양주시 광적면 현석로 313-44';
    final isGoingRetreat = detail.room.destination.contains(retreatAddress);

    final displayLocation = isGoingRetreat
        ? detail.room.origin
        : detail.room.destination;

    final displayLocationDetail = isGoingRetreat
        ? (detail.room.originDetailed.isNotEmpty
            ? detail.room.originDetailed
            : detail.room.origin)
        : (detail.room.destinationDetailed.isNotEmpty
            ? detail.room.destinationDetailed
            : detail.room.destination);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '카풀 정보',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place, size: 20, color: secondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('장소: $displayLocationDetail\n($displayLocation)'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: secondaryColor),
                  const SizedBox(width: 8),
                  Text('시간: ${DateFormat('M/d(E) a h:mm', 'ko').format(detail.room.departureTime)}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.drive_eta, size: 20, color: secondaryColor),
                  const SizedBox(width: 8),
                  Text('운전자: ${detail.room.driver.name} (${detail.room.driver.phone})'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);
    final currentUserId = loginState.user?.id;

    if (currentUserId == null) {
      return const Center(child: Text("로그인 정보 없음"));
    }

    final chatItems = ref.watch(chatViewModelProvider(widget.roomId));
    final chatViewModel = ref.read(chatViewModelProvider(widget.roomId).notifier);

    final carpoolDetail = ref.watch(chatRoomDetailProvider(widget.roomId));
    final int? driverId = chatViewModel.driverId;
    final String driverName = carpoolDetail?.room.driver.name ?? '운전자';
    // 현재 인원
    int currentMembers = (carpoolDetail?.room.seatsTotal ?? 0) - (carpoolDetail?.room.seatsLeft ?? 0);
    int maxMembers = carpoolDetail?.room.seatsTotal ?? 0;

    final bool isArrived = carpoolDetail?.room.status == CarpoolStatus.arrived ?? false;

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
          centerTitle: false,
          title: Text('$driverName님 카풀 메시지'),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (carpoolDetail != null)
                  Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text(
                      '$currentMembers/$maxMembers',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                InkWell(
                  onTap: () {
                    // ref.read(carpoolMembersProvider(widget.roomId).notifier).loadMembers();
                    _showMembersPopup(context, widget.roomId, currentUserId);
                  },
                  child: const Icon(Icons.people, color: secondaryColor),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    _showCarpoolInfo(context, carpoolDetail);
                  },
                  child: const Icon(Icons.info_outline, color: secondaryColor),
                ),
                const SizedBox(width: 12), // 끝 여백
              ],
            ),
          ]
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
                          chatItem,
                          isMine,
                          currentUserId,
                          driverId,
                          onResend: (chat) => chatViewModel.retryMessage(chat),
                          onDelete: (chat) => chatViewModel.deleteFailedMessage(chat),
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
                _buildInputField(chatViewModel, isArrived),
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

  Widget _buildMessageBubble(ChatMessageItem chatItem, bool isMine, int? currentUserId, int? driverId,    
    {
      required void Function(Chat) onResend,
      required void Function(Chat) onDelete,
    }
  ) {
    final message = chatItem.chat;
    final status = chatItem.status;
    final senderName = chatItem.senderName;
    final timeText = _formatTime(message.timestamp);
    final bool isDriver = message.senderId == driverId;
    final bool showSenderInfo = !isMine;

    Widget timeWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(timeText, style: _timeStyle),
    );

    return Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showSenderInfo && senderName.isNotEmpty)
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
                if (isDriver)
                  const Icon(Icons.drive_eta, size: 20, color: secondaryColor)
                else
                  const Icon(Icons.person, size: 20, color: text800Color),
                const SizedBox(width: 4),
                Text(
                  senderName,
                  style: const TextStyle(
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
          child: Padding( 
            padding: EdgeInsets.only(
              bottom: isMine ? 0.0 : 1.0,
              // top: 4.0 // 위쪽 간격
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isMine) timeWidget,
                _messageContainer(message.message, isMine),
                if (!isMine) timeWidget,
              ],
            ),
          ),
        ),
        if (status == ChatStatus.loading)
          Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              '전송 중...',
              style: TextStyle(fontSize: 10, color: text700Color),
            ),
          ),
        if (status == ChatStatus.failed)
          Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        icon: const Icon(Icons.refresh, size: 14, color: secondaryColor),
                        tooltip: '재전송',
                        onPressed: () => onResend(chatItem.chat),
                        visualDensity: VisualDensity.compact, // 내부 여백 축소
                        padding: EdgeInsets.zero, // 버튼 padding 제거
                        constraints: const BoxConstraints(), // 기본 크기 제한 제거
                      ),
                    ),
                    // const SizedBox(width: 1), // 버튼 사이 간격
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                        tooltip: '삭제',
                        onPressed: () => onDelete(chatItem.chat),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
    );
  }

  Widget _messageContainer(String text, bool isMine) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
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

  Widget _buildInputField(ChatViewModel chatViewModel, bool isArrived) {
    final String hintText = isArrived ? '카풀이 종료되어 메시지를 보낼 수 없습니다.' : '메시지를 입력하세요.';
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isArrived ? Colors.grey[200] : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: isArrived ? Colors.transparent : Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 3,
                readOnly: isArrived,
                enabled: !isArrived,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: isArrived ? Colors.grey : null),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            GestureDetector(
              onTap: isArrived
                ? null
                : () {
                    final text = _textController.text.trim();
                    if (text.isEmpty) return;
                    chatViewModel.sendMessage(text);
                    _textController.clear();
                    _scrollToBottom();
                  },
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.send, 
                  color: isArrived? Colors.grey : secondaryColor,
                  size: 26),
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