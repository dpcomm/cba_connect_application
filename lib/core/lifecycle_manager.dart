import 'package:cba_connect_application/dto/delete_fcm_token_dto.dart';
import 'package:cba_connect_application/dto/regist_fcm_dto.dart';
import 'package:cba_connect_application/repositories/fcm_repository.dart';
import 'package:flutter/material.dart';
import 'package:cba_connect_application/core/secure_storage.dart';


class LifecycleManager with WidgetsBindingObserver {
  final int userId;

  LifecycleManager(this.userId);

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }
  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      print('앱이 백그라운드로 전환됨');
      await SecureStorage.write(key: 'notification-config', value: 'off'); 
    } else if (state == AppLifecycleState.resumed) {
      print('앱이 포그라운드로 복귀');
      await SecureStorage.write(key: 'notification-config', value: 'on');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

