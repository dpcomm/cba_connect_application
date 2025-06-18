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


//Android 8 (API 26) 이상부터는 채널설정이 필수.
const androidChatNotificationChannel = AndroidNotificationChannel(
  'chat_channel', // id
  'Chat_Notifications', // name
  description: '채팅 알림 채널.',
  // description
  importance: Importance.high,
  playSound: false,
);

const androidCarpoolNotificationChannel = AndroidNotificationChannel(
  'carpool_channel', 
  'Carpool_Notifications',
  description: '카풀 알림 채널',
  importance: Importance.high,
  playSound: false,  
);

Future<void> initializeFirebaseAppSettings() async {

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }


  FirebaseMessaging fbMsg = FirebaseMessaging.instance;

  // 플랫폼 확인후 권한요청 및 Flutter Local Notification Plugin 설정
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel? androidNotificationChannel;
  if (Platform.isIOS) {
    //await reqIOSPermission(fbMsg);
  } else if (Platform.isAndroid) {
    await FirebaseMessaging.instance.requestPermission();




    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChatNotificationChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidCarpoolNotificationChannel);


  }
  //Background Handling 백그라운드 메세지 핸들링
  FirebaseMessaging.onBackgroundMessage(fbMsgBackgroundHandler);
  //Foreground Handling 포어그라운드 메세지 핸들링
  FirebaseMessaging.onMessage.listen((message) {
    fbMsgForegroundHandler(
        message, flutterLocalNotificationsPlugin);
  });
  //Message Click Event Implement
  await setupInteractedMessage(fbMsg);

}


/// Firebase Background Messaging 핸들러
@pragma('vm:entry-point')
Future<void> fbMsgBackgroundHandler(RemoteMessage message) async {
  print("[FCM - Background] MESSAGE : ${message.messageId}");
  final notificationConfig = await SecureStorage.read(key: 'notification-config');
  if (notificationConfig == 'off') return;

  final notificationConfigNow = await SecureStorage.read(key: 'notification-config-now');
  if (notificationConfigNow == 'off') return;
  
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

  final channelId = message.data['channelId'];

  if (channelId == 'chat_channel') {
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
            channel.id,
            channel.name,
            groupKey: message.data['roomId'],
            channelDescription: channel.description,
            importance: channel.importance,
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
            channel.id,
            channel.name,
            groupKey: message.data['roomId'],
            setAsGroupSummary: true,
            channelDescription: channel.description,
            importance: channel.importance,
            playSound: false,
          ),
          // iOS: const DarwinNotificationDetails(
          //   badgeNumber: 1,
          //   subtitle: 'the subtitle',
          //   sound: 'slow_spring_board.aiff',
          // ),
        ));        
  } else if (channelId == 'carpool_channel') {
    
    channel = AndroidNotificationChannel(
      'carpool_channel', 
      'Carpool_Notifications',
      description: '카풀 알림 채널',
      importance: Importance.high,
      playSound: false,  
    );

    flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.data['title'],
        message.data['body'],
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            playSound: false,
          ),
          // iOS: const DarwinNotificationDetails(
          //   badgeNumber: 1,
          //   subtitle: 'the subtitle',
          //   sound: 'slow_spring_board.aiff',
          // ),
        ));
  } else {
    channel = AndroidNotificationChannel(
      'default_channel', 
      'Default_Notifications',
      description: '기본 알림 채널',
      importance: Importance.defaultImportance,
      playSound: false,  
    );

    flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.data['title'],
        message.data['body'],
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            playSound: false,
          ),
          // iOS: const DarwinNotificationDetails(
          //   badgeNumber: 1,
          //   subtitle: 'the subtitle',
          //   sound: 'slow_spring_board.aiff',
          // ),
        ));
  }
}

/// Firebase Foreground Messaging 핸들러
Future<void> fbMsgForegroundHandler(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  print('[FCM - Foreground] MESSAGE : ${message.data}');

  final notificationConfig = await SecureStorage.read(key: 'notification-config');
  if (notificationConfig == 'off') return;

  final notificationConfigNow = await SecureStorage.read(key: 'notification-config-now');
  if (notificationConfigNow == 'off') return;


  AndroidNotificationDetails androidDetails;

  final channelId = message.data['channelId'];

  if (channelId == 'chat_channel') {
    androidDetails = AndroidNotificationDetails(
      androidChatNotificationChannel.id,
      androidChatNotificationChannel.name,
      groupKey: message.data['roomId'],
      channelDescription: androidChatNotificationChannel.description,
      importance: androidChatNotificationChannel.importance,
      playSound: false,
    );
  } else if (channelId == 'carpool_channel') {
    androidDetails = AndroidNotificationDetails(
      androidCarpoolNotificationChannel.id,
      androidCarpoolNotificationChannel.name,
      channelDescription: androidCarpoolNotificationChannel.description,
      importance: androidCarpoolNotificationChannel.importance,
      playSound: false,
    );    
  } else {
    androidDetails = AndroidNotificationDetails(
      'default_channel',
      'default notification',
      channelDescription: '기본 알림 채널',
      importance: Importance.defaultImportance,
      playSound: false,
    );        
  }

  if (channelId == 'chat_channel') {
    flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.data['title'],
        message.data['body'],
        NotificationDetails(
          android: AndroidNotificationDetails(
            androidChatNotificationChannel.id,
            androidChatNotificationChannel.name,
            groupKey: message.data['roomId'],
            channelDescription: androidChatNotificationChannel.description,
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
            androidChatNotificationChannel.id,
            androidChatNotificationChannel.name,
            groupKey: message.data['roomId'],
            setAsGroupSummary: true,
            channelDescription: androidChatNotificationChannel.description,
            icon: '@mipmap/ic_launcher',
            playSound: false,
          ),
          // iOS: const DarwinNotificationDetails(
          //   badgeNumber: 1,
          //   subtitle: 'the subtitle',
          //   sound: 'slow_spring_board.aiff',
          // ),
        ));        
  } else {
    flutterLocalNotificationsPlugin.show(
      message.hashCode, 
      message.data['title'],
      message.data['body'],
      NotificationDetails(
        android: androidDetails,
        // iOS: const DarwinNotificationDetails(
        //   badgeNumber: 1,
        //   subtitle: 'the subtitle',
        //   sound: 'slow_spring_board.aiff',
        // ),        
      ),
    );
  }



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

