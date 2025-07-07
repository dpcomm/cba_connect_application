import 'package:cba_connect_application/presentation/main/pages/home/registration/registration_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/core/custom_exception.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart';


enum CarpoolSearchStatus { initial, loading, success, error }

/// 카풀 검색 상태 객체
class CarpoolSearchState {
  final CarpoolSearchStatus status;
  final List<CarpoolRoom> rooms;
  final String? message;

  const CarpoolSearchState({
    this.status = CarpoolSearchStatus.initial,
    this.rooms = const [],
    this.message,
  });
}

class CarpoolSearchViewModel extends StateNotifier<CarpoolSearchState> {
  final CarpoolRepository _repository;

  CarpoolSearchViewModel(this._repository) : super(const CarpoolSearchState());

  /// 전체 카풀 목록 불러오기
  Future<void> fetchAll({String? origin, String? destination}) async {
    state = const CarpoolSearchState(status: CarpoolSearchStatus.loading);
    try {
      final list = await _repository.getAllCarpools();
      print(list);

      final beforeDeapartedList = list.where((room) => room.status == CarpoolStatus.beforeDeparture).toList();

      state = CarpoolSearchState(
        status: CarpoolSearchStatus.success,
        rooms: beforeDeapartedList,
      );
    } on NetworkException catch (e) {
      state = CarpoolSearchState(
        status: CarpoolSearchStatus.error,
        message: e.message,
      );
    } catch (e) {
      state = CarpoolSearchState(
        status: CarpoolSearchStatus.error,
        message: e.toString(),
      );
    }
  }
}

final carpoolSearchProvider = StateNotifierProvider<
    CarpoolSearchViewModel,
    CarpoolSearchState
>((ref) {
  final repo = ref.read(carpoolRepositoryProvider);
  return CarpoolSearchViewModel(repo);
});
