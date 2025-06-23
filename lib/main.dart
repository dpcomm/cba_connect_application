import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/config/app_config.dart';
import 'package:cba_connect_application/firebaseService/initialize_firebase.dart';
import 'package:cba_connect_application/presentation/login/login_view.dart';
import 'package:cba_connect_application/presentation/main/main_view.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  String? flavor = await const MethodChannel('flavor').invokeMethod<String>('getFlavor');
  Config(flavor);

  // 스플레시 화면 수정은 pubspec.yaml에서 수정,
  // 수정이 끝나면 터미널에 flutter pub run flutter_native_splash:create 명령어로 반영
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initializeDateFormatting('ko', null);
  /**
   * 해당 부분에 권한 요청 및 기타 API 처리, 혹은 버전 및 업데이트 확인 코드 넣으면 됨.
   */
  await initializeFirebaseAppSettings();

  runApp(const AppRoot());
  FlutterNativeSplash.remove();
}

class AppRoot extends StatefulWidget {
  const AppRoot({Key? key}) : super(key: key);

  @override
  State<AppRoot> createState() => _AppRootState();

  static void resetProviders() {
    final state = _AppRootState.instance;
    state?._resetScope();
  }
}

class _AppRootState extends State<AppRoot> {
  static _AppRootState? instance;
  Key _scopeKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    instance = this;
  }

  void _resetScope() {
    setState(() => _scopeKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: _scopeKey,
      child: MaterialApp(
        title: 'CBA Connect 카풀',
        initialRoute: '/',
        routes: {
          '/': (_) => LoginView(),
          '/main': (_) => MainView(),
        },
      ),
    );
  }
}
