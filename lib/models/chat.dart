class Chat {
    final int senderId;
    final int roomId;
    final String message;
    final DateTime timestamp;

    Chat({
        required this.senderId,
        required this.roomId,
        required this.message,
        required this.timestamp,
    });

    factory Chat.fromJson(Map<String, dynamic> json) {
        return Chat(
            senderId: json['senderId'] as int,
            roomId: json['roomId'] as int,
            message: json['message'] as String,
            timestamp: DateTime.parse(json['timestamp'] as String),
        );
    }    
}