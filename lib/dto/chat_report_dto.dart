class ReportChatDto {
  final int reporter;
  final int reported;
  final int roomId;
  final String reason;

  ReportChatDto({
    required this.reporter,
    required this.reported,
    required this.roomId,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'reporterId': reporter,
    'reportedId': reported,
    'roomid': roomId,
    'reason': reason,
  };
}