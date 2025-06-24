import 'package:cba_connect_application/config/app_config.dart';
import 'package:cba_connect_application/core/version_checker.dart';
import 'package:cba_connect_application/presentation/login/login_view.dart';
import 'package:cba_connect_application/presentation/splash/splash_view_model.dart';
import 'package:cba_connect_application/presentation/update/update_view.dart';
import 'package:cba_connect_application/presentation/widgets/consent_modal.dart';
import 'package:cba_connect_application/presentation/main/main_view.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cba_connect_application/firebaseService/initialize_firebase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  final _versionChecker = VersionChecker();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: const Color(0xFF5A26A9),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) => _startFlow());
  }

  Future<void> _startFlow() async {
    if (await _versionChecker.isUpdateNeeded()) {
      final versions = await _versionChecker.getVersions();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => UpdateView(
            currentVersion: versions['current']!,
            latestVersion:  versions['latest']!,
          ),
        ),
      );
      return;
    }


    /// 버전 체크
    if (Config.instance.flavor == "prod") {
      if (await _versionChecker.isUpdateNeeded()) {
        final versions = await _versionChecker.getVersions();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => UpdateView(
              currentVersion: versions['current']!,
              latestVersion:  versions['latest']!,
            ),
          ),
        );
        return;
      }
    }

    await Future.delayed(const Duration(seconds: 2));

    /// 푸시 권한 요청 및 파이어베이스 연결
    await initializeFirebaseAppSettings();
    await initializeDateFormatting('ko', null);


    /// 자동로그인 체크
    final loginNotifier = ref.read(loginViewModelProvider.notifier);
    await loginNotifier.refreshLogin();
    final loginState = ref.read(loginViewModelProvider);

    await Future.delayed(const Duration(seconds: 2));

    /// 자동로그인 체크 후 화면 분기
    await Future.delayed(const Duration(milliseconds: 500));
    if (loginState.status == LoginStatus.success) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainView(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
      return;
    }

    /// 권한 및 동의 체크
    if (await ref.read(splashViewModelProvider.notifier).checkUserConsent() == false) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ConsentModal(
          onConfirm: () async {
            /// 개인정보 수집/제공 동의 확인 저장
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('consentPrivacyPolicy', true);

            /// 모달 종료
            Navigator.of(ctx).pop();
          },
        ),
      );
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginView(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5A26A9),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Image.asset(
                'assets/images/carpool_service_icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/recba_branding_icon.png',
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
