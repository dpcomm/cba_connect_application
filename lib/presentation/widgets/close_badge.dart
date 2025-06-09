import 'package:flutter/material.dart';

class CloseBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const CloseBadge({
    Key? key,
    this.text = '마감',
    this.backgroundColor = const Color(0xFFEF5350), // 빨간색
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        text,
        style: textStyle ??
            const TextStyle(
              fontSize: 10,
              color: Colors.white,
            ),
      ),
    );
  }
}