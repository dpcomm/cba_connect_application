import 'package:cba_connect_application/core/provider.dart';
import 'package:cba_connect_application/dto/refresh_fcm_token_dto.dart';
import 'package:cba_connect_application/dto/regist_fcm_dto.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';
import 'package:cba_connect_application/repositories/fcm_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cba_connect_application/config/firebase_options_dev.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:cba_connect_application/core/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';



class FcmService{
  final FcmRepository _repo;

  FirebaseMessaging fbMsg = FirebaseMessaging.instance;


  FcmService(this._repo);

  Future<void> setToken(int userId) async {
    final tokenExists = await SecureStorage.read(key: 'firebase-token');
    print("--------------------------tokenexists-------------------------------");
    print(tokenExists);
    print("--------------------------tokenexists-------------------------------");
    if(tokenExists == null) {
      print("token is not exist");
      var fcmToken = await FirebaseMessaging.instance.getToken();
      print("get token: $fcmToken");
      if (fcmToken != null) {
        await SecureStorage.write(key: 'firebase-token', value: fcmToken);        
        await _repo.registToken(RegistFcmDto(
          userId: userId,
          token: fcmToken,
          platform: Platform.isIOS? "ios" : "android",
        ));
      }  
    }

    fbMsg.onTokenRefresh.listen((nToken) async {
      if(tokenExists == null) {
        await SecureStorage.write(key: 'firebase-token', value: nToken);        
        await _repo.registToken(RegistFcmDto(
          userId: userId,
          token: nToken,
          platform: Platform.isIOS? "ios" : "android",
        ));
      } else {
        await SecureStorage.write(key: 'firebase-token', value: nToken);        
        await _repo.refreshToken(RefreshFcmTokenDto(
          userId: userId, 
          oldToken: tokenExists, 
          newToken: nToken,
          platform: Platform.isIOS? "ios" : "android",
          ));
      }
    });
    
  }

  
}