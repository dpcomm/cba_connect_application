import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart';
import '/core/custom_exception.dart';
import 'package:cba_connect_application/presentation/main/pages/home/registration/registration_view_model.dart';

enum MyCarpoolDetailStatus { initial, loading, success, left, deleted, error }

class MyCarpoolDetailState {
  final MyCarpoolDetailStatus status;
  final CarpoolRoomDetail? roomDetail;
  final String? message;

  const MyCarpoolDetailState({
    this.status = MyCarpoolDetailStatus.initial,
    this.roomDetail,
    this.message,
  });

  MyCarpoolDetailState copyWith({
    MyCarpoolDetailStatus? status,
    CarpoolRoomDetail? roomDetail,
    String? message,
  }) {
    return MyCarpoolDetailState(
      status: status ?? this.status,
      roomDetail: roomDetail ?? this.roomDetail, 
      message: message ?? this.message,
    );
  }
}

class MyCarpoolDetailPageViewModel extends StateNotifier<MyCarpoolDetailState> {
  final CarpoolRepository _repository;

  MyCarpoolDetailPageViewModel(this._repository)
      : super(const MyCarpoolDetailState());

  /// 카풀 상세 정보 불러오기 (초기 로딩 시 사용)
  Future<void> fetchCarpoolDetail(int id) async {
    state = state.copyWith(status: MyCarpoolDetailStatus.loading);
    try {
      final fetchedDetail = await _repository.fetchCarpoolDetails(id);
      state = state.copyWith(
        status: MyCarpoolDetailStatus.success,
        roomDetail: fetchedDetail,
      );
    } on NetworkException catch (e) {
      state = state.copyWith(
        status: MyCarpoolDetailStatus.error,
        message: e.message,
      );
      print('카풀 상세 정보 로드 실패: ${e.message}'); // 에러 로깅
    } catch (e) {
      state = state.copyWith(
        status: MyCarpoolDetailStatus.error,
        message: '알 수 없는 에러 발생: $e',
      );
      print('알 수 없는 에러: $e');
    }
  }

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

  /// 카풀 출발 (운전자 입장)
  Future<void> markCarpoolAsDeparted(int roomId) async {
    state = state.copyWith(status: MyCarpoolDetailStatus.loading, message: '카풀 출발 처리 중...');
    try {
      await _repository.updateCarpoolStatus(roomId, CarpoolStatus.inTransit.toApiString());
      await _repository.sendStartNotification(roomId);

      final currentRoomDetail = state.roomDetail;
      if (currentRoomDetail != null) {
        final currentRoom = currentRoomDetail.room;
        final updatedRoom = currentRoom.copyWith(status: CarpoolStatus.inTransit);
        final updatedRoomDetail = CarpoolRoomDetail(room: updatedRoom, members: currentRoomDetail.members);

        state = state.copyWith(
          status: MyCarpoolDetailStatus.success,
          message: '카풀 운행을 시작합니다! 안전 운행 하세요 :)',
          roomDetail: updatedRoomDetail,
        );
      } else {
        state = state.copyWith(
          status: MyCarpoolDetailStatus.success,
          message: '카풀 운행을 시작합니다! 안전 운행 하세요 :)',
        );
      }
    } on CustomException catch (e) {
      state = state.copyWith(status: MyCarpoolDetailStatus.error, message: e.message);
    } catch (e) {
      state = state.copyWith(status: MyCarpoolDetailStatus.error, message: '카풀 출발 처리에 실패했습니다: ${e.toString()}');
    }
  }
}

final myCarpoolDetailPageProvider = StateNotifierProvider<MyCarpoolDetailPageViewModel, MyCarpoolDetailState>(
    (ref) {
      final repo = ref.read(carpoolRepositoryProvider);
      return MyCarpoolDetailPageViewModel(repo);
    },
);