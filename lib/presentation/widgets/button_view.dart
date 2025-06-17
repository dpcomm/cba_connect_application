import 'package:flutter/material.dart';

class ButtonView extends StatelessWidget {
  final bool isOwner;       // 운전자 여부
  final bool isApplied;     // 이미 참여했는지
  final bool isFull;        // 마감 여부(정원 초과)
  final VoidCallback? onApply;    // 카풀 신청
  final VoidCallback? onConfirm;  // 카풀 확정
  final VoidCallback? onMessage;  // 메시지

  const ButtonView({
    Key? key,
    required this.isOwner,
    required this.isApplied,
    required this.isFull,
    this.onApply,
    this.onConfirm,
    this.onMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 운전자이거나 이미 참여했거나 마감이면: 두 개 버튼
    final showDoubleButton = isOwner || isApplied || isFull;

    if (showDoubleButton) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              // 마감(isFull)이면 비활성화, 아니면 onConfirm
              onPressed: isFull ? null : onConfirm,
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, 48),
                side: BorderSide(color: Color(0xFF7F19FB), width: 2),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                '카풀 확정',
                style: TextStyle(
                  color: Color(0xFF7F19FB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: onMessage,
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, 48),
                side: BorderSide(color: Colors.black, width: 2),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                '메시지',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // 미참여 참여자: 긴 보라색 버튼
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onApply,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(0, 48),
            backgroundColor: Color(0xFF7F19FB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 2,
          ),
          child: Text(
            '카풀 신청 하기',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}
