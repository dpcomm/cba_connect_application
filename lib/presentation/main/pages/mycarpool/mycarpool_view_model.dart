import 'package:cba_connect_application/presentation/main/pages/home/registration/registration_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/core/custom_exception.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart';


enum CarpoolListStatus { initial, loading, success, error }

/// 카풀 검색 상태 객체
class CarpoolListState {
  final CarpoolListStatus status;
  final List<CarpoolRoom> rooms;
  final String? message;

  const CarpoolListState({
    this.status = CarpoolListStatus.initial,
    this.rooms = const [],
    this.message,
  });

  // 상태를 복사하면서 특정 필드만 변경하는 copyWith 메서드 추가
  CarpoolListState copyWith({
    CarpoolListStatus? status,
    List<CarpoolRoom>? rooms,
    String? message,
  }) {
    return CarpoolListState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      message: message ?? this.message,
    );
  }
}

class MyCarpoolViewModel extends StateNotifier<CarpoolListState> {
  final CarpoolRepository _repository;

  MyCarpoolViewModel(this._repository)
      : super(const CarpoolListState());

  Future<void> fetchMyCarpools(int userId) async {
    state = state.copyWith(status: CarpoolListStatus.loading);
    try {
      final list = await _repository.getMyCarpools(userId);
      state = state.copyWith(
        status: CarpoolListStatus.success,
        rooms: list,
      );
    } catch (e) {
      state = state.copyWith(
        status: CarpoolListStatus.error,
        message: e.toString(),
      );
    }
  }
}

final myCarpoolProvider =
    StateNotifierProvider<MyCarpoolViewModel, CarpoolListState>((ref) {
  final repo = ref.read(carpoolRepositoryProvider);
  return MyCarpoolViewModel(repo);
});