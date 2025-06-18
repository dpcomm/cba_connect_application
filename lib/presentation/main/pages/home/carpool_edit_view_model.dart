import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/dto/update_carpool_info_dto.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart';
import 'package:cba_connect_application/presentation/main/pages/home/registration_view_model.dart';

enum CarpoolEditStatus { initial, loading, success, error }

class CarpoolEditState {
  final CarpoolEditStatus status;
  final String? errorMessage;
  final CarpoolRoom? updatedCarpool;

  CarpoolEditState({
    this.status = CarpoolEditStatus.initial,
    this.errorMessage,
    this.updatedCarpool,
  });

  CarpoolEditState copyWith({
    CarpoolEditStatus? status,
    String? errorMessage,
    CarpoolRoom? updatedCarpool,
  }) {
    return CarpoolEditState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      updatedCarpool: updatedCarpool ?? this.updatedCarpool,
    );
  }
}

class CarpoolEditViewModel extends StateNotifier<CarpoolEditState> {
  final CarpoolRepository _carpoolRepository;

  CarpoolEditViewModel(this._carpoolRepository) : super(CarpoolEditState());

  Future<void> editCarpool(UpdateCarpoolInfoDto dto) async {
    state = state.copyWith(status: CarpoolEditStatus.loading);
    try {
      final updatedRoom = await _carpoolRepository.editCarpool(dto);
      state = state.copyWith(status: CarpoolEditStatus.success, updatedCarpool: updatedRoom);
    } catch (e) {
      state = state.copyWith(status: CarpoolEditStatus.error, errorMessage: e.toString());
    }
  }
}

final carpoolEditViewModelProvider = StateNotifierProvider<CarpoolEditViewModel, CarpoolEditState> ((ref) {
  final repo = ref.read(carpoolRepositoryProvider);
  return CarpoolEditViewModel(repo);
});