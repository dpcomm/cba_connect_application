import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/config/app_config.dart';
import 'package:cba_connect_application/presentation/splash//splash_view.dart';
import 'package:cba_connect_application/presentation/login/login_view.dart';
import 'package:cba_connect_application/presentation/main/main_view.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? flavor = await const MethodChannel('flavor').invokeMethod<String>('getFlavor');
  Config(flavor);
  runApp(const AppRoot());
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
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => SplashView(),
          '/login': (_) => LoginView(),
          '/main': (_) => MainView(),
        },
      ),
    );
  }
}
