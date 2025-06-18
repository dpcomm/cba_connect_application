import 'package:cba_connect_application/dto/delete_fcm_token_dto.dart';
import 'package:cba_connect_application/dto/regist_fcm_dto.dart';
import 'package:cba_connect_application/repositories/fcm_repository.dart';
import 'package:flutter/material.dart';
import 'package:cba_connect_application/core/secure_storage.dart';


class LifecycleManager with WidgetsBindingObserver {
  final int userId;
  final FcmRepository _repo;

  LifecycleManager(this.userId, this._repo);

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
      final token = await SecureStorage.read(key: 'firebase-token');
      if (token != null) { await _repo.deleteToken(DeleteFcmTokenDto(token: token)); }
    } else if (state == AppLifecycleState.resumed) {
      print('앱이 포그라운드로 복귀');
      final token = await SecureStorage.read(key: 'firebase-token');
      if (token != null) { await _repo.registToken(RegistFcmDto(userId: userId, token: token)); }
      // 서버에 "포그라운드 복귀" 알림 등
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

