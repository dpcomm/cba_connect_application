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
    
    Chat copyWith({
      int? senderId,
      int? roomId,
      String? message,
      DateTime? timestamp,
    }) {
      return Chat(
        senderId: senderId ?? this.senderId,
        roomId: roomId ?? this.roomId,
        message: message ?? this.message,
        timestamp: timestamp ?? this.timestamp,
      );
    }

    factory Chat.fromJson(Map<String, dynamic> json) {
        return Chat(
            senderId: json['senderId'] as int,
            roomId: json['roomId'] as int,
            message: json['message'] as String,
            timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
        );
    }    

    Map<String, dynamic> toJson() {
      return {
        'senderId': senderId,
        'roomId': roomId,
        'message': message,
        'timestamp': timestamp.toUtc().toIso8601String(),
      };
    }
}

enum ChatStatus { loading, success, failed, deleted }
