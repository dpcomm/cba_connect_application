import 'package:cba_connect_application/core/lifecycle_manager.dart';
import 'package:cba_connect_application/presentation/chat/chat_view_model.dart';
import 'package:cba_connect_application/presentation/main/pages/home/registration_view_model.dart';
import 'package:cba_connect_application/repositories/chat_repository.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/core/socket_manager.dart';
import 'package:cba_connect_application/socket_event_handler/chat_event_handler.dart';
import 'package:cba_connect_application/models/chat_item.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';

import 'package:cba_connect_application/datasources/fcm_data_source.dart';
import 'package:cba_connect_application/repositories/fcm_repository.dart';
import 'package:cba_connect_application/firebaseService/fcm_service.dart';

import 'package:cba_connect_application/datasources/chat_report_datasource.dart';
import 'package:cba_connect_application/repositories/chat_report_repository.dart';

final socketManagerProvider = Provider((ref) => SocketManager());

final chatEventHandlerProvider = Provider((ref) {
  final socket = ref.watch(socketManagerProvider).socket;
  return ChatEventHandler(socket);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final handler = ref.watch(chatEventHandlerProvider);
  return ChatRepository(handler: handler);
});

final chatViewModelProvider = StateNotifierProvider.family
    .autoDispose<ChatViewModel, List<ChatItem>, int>((ref, roomId) {
      final repository = ref.watch(chatRepositoryProvider);
      final carpoolRepository = ref.watch(carpoolRepositoryProvider);
      return ChatViewModel(roomId: roomId, repository: repository, carpoolRepository: carpoolRepository, ref: ref);
});




// DataSource 프로바이더
final fcmDataSourceProvider = Provider<FcmDataSource>((ref) {
  return FcmDataSourceImpl();
});

// Repository 프로바이더

final fcmRepositoryProvider = Provider<FcmRepository>((ref) {
  final dataSource = ref.read(fcmDataSourceProvider);
  return FcmRepositoryImpl(dataSource);
});

// ViewModel 프로바이더
// ViewModel에 authRepository를 주입.
final fcmServiceProvider = Provider<FcmService>((ref) {
  final repository = ref.read(fcmRepositoryProvider);
  return FcmService(repository);
});


// LifecycleManager를 userId별로 관리 (family 사용)
final lifecycleManagerProvider = Provider.family.autoDispose<LifecycleManager, int>((ref, userId) {
  final repository = ref.read(fcmRepositoryProvider);
  return LifecycleManager(userId, repository);
});


// DataSource 프로바이더
final chatreportDataSourceProvider = Provider<ChatreportDataSource>((ref) {
  return ChatreportDataSourceImpl();
});

// Repository 프로바이더

final chatreportRepositoryProvider = Provider<ChatreportRepository>((ref) {
  final dataSource = ref.read(chatreportDataSourceProvider);
  return ChatreportRepositoryImpl(dataSource);
});
