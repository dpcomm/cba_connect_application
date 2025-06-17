import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart';
import 'package:cba_connect_application/core/custom_exception.dart';

import '../main/pages/home/registration_view_model.dart';

enum MyCarpoolDetailStatus { initial, loading, success, left, deleted, error }

class MyCarpoolDetailState {
  final MyCarpoolDetailStatus status;
  final CarpoolRoom? room;
  final String? message;

  const MyCarpoolDetailState({
    this.status = MyCarpoolDetailStatus.initial,
    this.room,
    this.message,
  });

  MyCarpoolDetailState copyWith({
    MyCarpoolDetailStatus? status,
    CarpoolRoom? room,
    String? message,
  }) {
    return MyCarpoolDetailState(
      status: status ?? this.status,
      room: room ?? this.room,
      message: message ?? this.message,
    );
  }
}

class MyCarpoolDetailPageViewModel extends StateNotifier<MyCarpoolDetailState> {
  final CarpoolRepository _repository;

  MyCarpoolDetailPageViewModel(this._repository)
      : super(const MyCarpoolDetailState());

  /// 내 카풀 방에서 나가기 (참여자 입장)
  Future<void> leaveCarpool(int userId, int roomId) async {
    state = state.copyWith(status: MyCarpoolDetailStatus.loading);
    try {
      await _repository.leaveCarpool(userId: userId, roomId: roomId);
      state = state.copyWith(status: MyCarpoolDetailStatus.left);
    } on NetworkException catch (e) {
      state = state.copyWith(
        status: MyCarpoolDetailStatus.error,
        message: e.message,
      );
    }
  }

  /// 내 카풀 방 삭제 (운전자 입장)
  Future<void> deleteCarpool(int roomId) async {
    state = state.copyWith(status: MyCarpoolDetailStatus.loading);
    try {
      await _repository.deleteCarpool(roomId);
      state = state.copyWith(status: MyCarpoolDetailStatus.deleted);
    } on NetworkException catch (e) {
      state = state.copyWith(
        status: MyCarpoolDetailStatus.error,
        message: e.message,
      );
    }
  }
}

final myCarpoolDetailPageProvider = StateNotifierProvider<MyCarpoolDetailPageViewModel, MyCarpoolDetailState>(
    (ref) {
      final repo = ref.read(carpoolRepositoryProvider);
      return MyCarpoolDetailPageViewModel(repo);
    },
);