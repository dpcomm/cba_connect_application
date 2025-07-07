import 'dart:io';

import 'package:cba_connect_application/core/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateView extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;

  const UpdateView({
    Key? key,
    required this.currentVersion,
    required this.latestVersion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/carpool_service_icon_outline.png',
                  width: 120,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),

                Text(
                  '최적의 사용 환경을 위해 최신 버전의 앱으로 업데이트 해주세요.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // 버전 정보
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('현재 버전: ', style: theme.textTheme.titleMedium),
                    Text(currentVersion,
                        style: theme.textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('최신 버전: ', style: theme.textTheme.titleMedium),
                    Text(latestVersion,
                        style: theme.textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final storeUrl = Platform.isIOS
                          ? 'https://apps.apple.com/kr/app/cba-connect/id6747623245'
                          : 'https://play.google.com/store/apps/details?id=com.cba.cba_connect_application&pcampaignid=web_share';

                      final uri = Uri.parse(storeUrl);
                      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('스토어를 열 수 없습니다.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '업데이트',
                      style: theme.textTheme.labelLarge!
                          .copyWith(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}