import 'package:flutter/material.dart';
import 'chat_view.dart';

class CarpoolDetailPopup extends StatelessWidget {
  final int roomId;
  const CarpoolDetailPopup({Key? key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('카풀 roomId: $roomId', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // 팝업 닫기
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => ChatView(roomId: roomId)),
                // );
              },
              child: const Text('채팅방 들어가기'),
            ),
          ],
        ),
      ),
    );
  }
}
