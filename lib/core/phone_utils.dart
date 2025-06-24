import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> makePhoneCall(BuildContext context, String phone) async {
  print('[makePhoneCall] 시도 전화번호: $phone');

  if (phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전화번호가 유효하지 않습니다.')),
    );
    print('[makePhoneCall] 전화번호가 비어있습니다.');
    return;
  }

  final Uri launchUri = Uri(scheme: 'tel', path: phone);

  try {
    final bool canLaunchUri = await canLaunchUrl(launchUri);
    print('[makePhoneCall] canLaunchUrl 결과: $canLaunchUri');

    if (canLaunchUri) {
      await launchUrl(launchUri);
      print('[makePhoneCall] 전화 걸기 성공!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화를 걸 수 없습니다.')),
      );
      print('[makePhoneCall] canLaunchUrl이 false를 반환했습니다.');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('전화 걸기 중 오류 발생: $e')),
    );
    print('[makePhoneCall] 전화 걸기 중 예외 발생: $e');
  }
}
