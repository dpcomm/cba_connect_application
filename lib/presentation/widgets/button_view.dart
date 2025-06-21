import 'package:flutter/material.dart';

class ButtonView extends StatelessWidget {
  final bool isApplied;
  final VoidCallback? onPressed;

  const ButtonView({
    Key? key,
    required this.isApplied,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(
        isApplied ? Icons.check : Icons.directions_car,
        color: isApplied ? Colors.black : Colors.white,
      ),
      label: Text(
        isApplied ? '카풀 신청 완료' : '카풀 신청 하기',
        style: TextStyle(
          color: isApplied ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(150, 48),
        backgroundColor: isApplied ? Colors.white : const Color(0xFF7F19FB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 2,
        side: isApplied
            ? const BorderSide(color: Color(0xFF7F19FB), width: 1.5)
            : BorderSide.none,
      ),
    );
  }
}