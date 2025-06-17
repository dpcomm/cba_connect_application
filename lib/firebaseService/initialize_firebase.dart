import 'package:cba_connect_application/dto/regist_fcm_dto.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';
import 'package:cba_connect_application/repositories/fcm_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cba_connect_application/firebase_options.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:cba_connect_application/core/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> initializeFirebaseAppSettings() async {

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }


  FirebaseMessaging fbMsg = FirebaseMessaging.instance;

  // 플랫폼 확인후 권한요청 및 Flutter Local Notification Plugin 설정
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel? androidNotificationChannel;
  if (Platform.isIOS) {
    //await reqIOSPermission(fbMsg);
  } else if (Platform.isAndroid) {
    await FirebaseMessaging.instance.requestPermission();


    //Android 8 (API 26) 이상부터는 채널설정이 필수.
    androidNotificationChannel = const AndroidNotificationChannel(
      'chat_channel', // id
      'Chat_Notifications', // name
      description: '채팅 알림 채널.',
      // description
      importance: Importance.high,
      playSound: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }
  //Background Handling 백그라운드 메세지 핸들링
  FirebaseMessaging.onBackgroundMessage(fbMsgBackgroundHandler);
  //Foreground Handling 포어그라운드 메세지 핸들링
  FirebaseMessaging.onMessage.listen((message) {
    fbMsgForegroundHandler(
        message, flutterLocalNotificationsPlugin, androidNotificationChannel);
  });
  //Message Click Event Implement
  await setupInteractedMessage(fbMsg);

}


/// Firebase Background Messaging 핸들러
@pragma('vm:entry-point')
Future<void> fbMsgBackgroundHandler(RemoteMessage message) async {
  print("[FCM - Background] MESSAGE : ${message.messageId}");
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AndroidNotificationChannel? channel;
  if (Platform.isIOS) {
    //await reqIOSPermission(fbMsg);
  } else if (Platform.isAndroid) {
    await FirebaseMessaging.instance.requestPermission();
  }

    //Android 8 (API 26) 이상부터는 채널설정이 필수.
    channel = const AndroidNotificationChannel(
      'chat_channel', // id
      'Chat_Notifications', // name
      description: '채팅 알림 채널.',
      // description
      importance: Importance.high,
      playSound: false,
    );
  print('[FCM - Background] MESSAGE : ${message.data}');

  flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.data['title'],
      message.data['body'],
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel!.id,
          channel.name,
          groupKey: message.data['roomId'],
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          playSound: false,
        ),
        // iOS: const DarwinNotificationDetails(
        //   badgeNumber: 1,
        //   subtitle: 'the subtitle',
        //   sound: 'slow_spring_board.aiff',
        // ),
      ));

  flutterLocalNotificationsPlugin.show(
      int.parse(message.data['roomId']),
      message.data['title'],
      message.data['body'],
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel!.id,
          channel.name,
          groupKey: message.data['roomId'],
          setAsGroupSummary: true,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          playSound: false,
        ),
        // iOS: const DarwinNotificationDetails(
        //   badgeNumber: 1,
        //   subtitle: 'the subtitle',
        //   sound: 'slow_spring_board.aiff',
        // ),
      ));        

}

/// Firebase Foreground Messaging 핸들러
Future<void> fbMsgForegroundHandler(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    AndroidNotificationChannel? channel) async {
  print('[FCM - Foreground] MESSAGE : ${message.data}');


  flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.data['title'],
      message.data['body'],
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel!.id,
          channel.name,
          groupKey: message.data['roomId'],
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          playSound: false,
        ),
        // iOS: const DarwinNotificationDetails(
        //   badgeNumber: 1,
        //   subtitle: 'the subtitle',
        //   sound: 'slow_spring_board.aiff',
        // ),
      ));

  flutterLocalNotificationsPlugin.show(
      int.parse(message.data['roomId']),
      message.data['title'],
      message.data['body'],
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel!.id,
          channel.name,
          groupKey: message.data['roomId'],
          setAsGroupSummary: true,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          playSound: false,
        ),
        // iOS: const DarwinNotificationDetails(
        //   badgeNumber: 1,
        //   subtitle: 'the subtitle',
        //   sound: 'slow_spring_board.aiff',
        // ),
      ));        

  // if (message.notification != null) {
  //   print('Message also contained a notification: ${message.notification}');
  //   print('collapse key: ${message.collapseKey}');
  //   flutterLocalNotificationsPlugin.show(
  //       message.hashCode,
  //       message.notification?.title,
  //       message.notification?.body,
  //       NotificationDetails(
  //         android: AndroidNotificationDetails(
  //           channel!.id,
  //           channel.name,
  //           groupKey: message.data['roomId'],
  //           channelDescription: channel.description,
  //           icon: '@mipmap/ic_launcher',
  //           playSound: false,
  //         ),
  //         // iOS: const DarwinNotificationDetails(
  //         //   badgeNumber: 1,
  //         //   subtitle: 'the subtitle',
  //         //   sound: 'slow_spring_board.aiff',
  //         // ),
  //       ));

  //   flutterLocalNotificationsPlugin.show(
  //       int.parse(message.data['roomId']),
  //       message.notification?.title,
  //       message.notification?.body,
  //       NotificationDetails(
  //         android: AndroidNotificationDetails(
  //           channel!.id,
  //           channel.name,
  //           groupKey: message.data['roomId'],
  //           setAsGroupSummary: true,
  //           channelDescription: channel.description,
  //           icon: '@mipmap/ic_launcher',
  //           playSound: false,
  //         ),
  //         // iOS: const DarwinNotificationDetails(
  //         //   badgeNumber: 1,
  //         //   subtitle: 'the subtitle',
  //         //   sound: 'slow_spring_board.aiff',
  //         // ),
  //       ));        
  // }
}

/// FCM 메시지 클릭 이벤트 정의
Future<void> setupInteractedMessage(FirebaseMessaging fbMsg) async {
  RemoteMessage? initialMessage = await fbMsg.getInitialMessage();
  // 종료상태에서 클릭한 푸시 알림 메세지 핸들링
  if (initialMessage != null) clickMessageEvent(initialMessage);
  // 앱이 백그라운드 상태에서 푸시 알림 클릭 하여 열릴 경우 메세지 스트림을 통해 처리
  FirebaseMessaging.onMessageOpenedApp.listen(clickMessageEvent);
}

void clickMessageEvent(RemoteMessage message) {

}

