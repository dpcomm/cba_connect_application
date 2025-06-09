import 'package:cba_connect_application/models/chat.dart';

abstract class ChatItem {}

class ChatMessageItem implements ChatItem {
  final Chat chat;
  final ChatStatus status;

  ChatMessageItem({required this.chat, required this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageItem &&
          runtimeType == other.runtimeType &&
          chat == other.chat &&
          status == other.status);

  @override
  int get hashCode => chat.hashCode ^ status.hashCode;
}

// 안읽은 메세지 구분선
class UnreadDividerItem implements ChatItem {
  final String text;

  UnreadDividerItem({this.text = "여기까지 읽었습니다"});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnreadDividerItem &&
          runtimeType == other.runtimeType &&
          text == other.text);

  @override
  int get hashCode => text.hashCode;
}

// 날짜 구분선
class DateDividerItem implements ChatItem {
  final DateTime date;
  final String displayDate;

  DateDividerItem({required this.date, required this.displayDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DateDividerItem &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          displayDate == other.displayDate);

  @override
  int get hashCode => date.hashCode ^ displayDate.hashCode;
}
