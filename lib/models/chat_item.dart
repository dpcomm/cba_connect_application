import 'package:cba_connect_application/models/chat.dart';

abstract class ChatItem {
  DateTime get timestamp;
  ChatItemType get type;
}

class ChatMessageItem implements ChatItem {
  final Chat chat;
  final ChatStatus status;
  final String senderName;

  ChatMessageItem({required this.chat, required this.status, required this.senderName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageItem &&
          runtimeType == other.runtimeType &&
          chat == other.chat &&
          status == other.status && 
          senderName == other.senderName);

  @override
  int get hashCode => chat.hashCode ^ status.hashCode;

  @override
  DateTime get timestamp => chat.timestamp;

  @override
  ChatItemType get type => ChatItemType.message;
}

// 안읽은 메세지 구분선
class UnreadDividerItem implements ChatItem {
  final String text;
  final DateTime timestamp;

  UnreadDividerItem({this.text = "여기까지 읽었습니다", required this.timestamp});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnreadDividerItem &&
          runtimeType == other.runtimeType &&
          text == other.text);

  @override
  int get hashCode => text.hashCode;

  @override
  ChatItemType get type => ChatItemType.unreadDivider;
}

// 날짜 구분선
class DateDividerItem implements ChatItem {
  final DateTime date;

  DateDividerItem({required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DateDividerItem &&
          runtimeType == other.runtimeType &&
          date == other.date
      );

  @override
  int get hashCode => date.hashCode ^ hashCode;

  @override
  DateTime get timestamp => date;

  @override
  ChatItemType get type => ChatItemType.dateDivider;
}

enum ChatItemType { message, unreadDivider, dateDivider, }