import 'package:cba_connect_application/presentation/main/main_view.dart';
import 'package:flutter/material.dart';
import 'package:cba_connect_application/presentation/login/login_view.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CBA Connect 카풀',
      initialRoute: '/',
      routes: {
        '/': (_) => LoginView(),
        '/main': (_) => MainView(),
      },
    );
  }
}

void main() {
  // 스플레시 화면 수정은 pubspec.yaml에서 수정,
  // 수정이 끝나면 터미널에 flutter pub run flutter_native_splash:create 명령어로 반영
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  /**
   * 해당 부분에 권한 요청 및 기타 API 처리, 혹은 버전 및 업데이트 확인 코드 넣으면 됨.
   */
  runApp(ProviderScope(child: MyApp()));
  FlutterNativeSplash.remove();
}