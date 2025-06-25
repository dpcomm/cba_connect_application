import 'package:cba_connect_application/presentation/main/pages/home/registration/registration_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart';
import 'package:cba_connect_application/core/custom_exception.dart';

enum CardViewStatus { initial, loading, success, error, applied }

class CardViewState {
  final CardViewStatus status;
  final CarpoolRoom? room;
  final List<CarpoolUserInfo> members;
  final String? message;

  const CardViewState({
    this.status = CardViewStatus.initial,
    this.room,
    this.members = const [],
    this.message,
  });
}

class CarpoolDetailPageViewModel extends StateNotifier<CardViewState> {
  final CarpoolRepository _repo;

  CarpoolDetailPageViewModel(this._repo) : super(const CardViewState());

  Future<void> fetchById(int id) async {
    state = const CardViewState(status: CardViewStatus.loading);
    try {
      final room = await _repo.fetchCarpoolDetails(id);
      state = CardViewState(
        status: CardViewStatus.success,
        room: room.room,
        members: room.members
      );
    } on NetworkException catch (e) {
      state = CardViewState(
        status: CardViewStatus.error,
        message: e.message,
      );
    } catch (e) {
      state = CardViewState(
        status: CardViewStatus.error,
        message: e.toString(),
      );
    }
  }

  Future<void> joinCarpool(int userId, int roomId) async {
    final previous = state.room;
    state = const CardViewState(status: CardViewStatus.loading);
    try {
      await _repo.joinCarpool(userId: userId, roomId: roomId);
      state = CardViewState(
        status: CardViewStatus.applied,
        room: previous,
      );
    } on NetworkException catch (e) {
      state = CardViewState(
        status: CardViewStatus.error,
        message: e.message,
      );
    } catch (e) {
      state = CardViewState(
        status: CardViewStatus.error,
        message: e.toString(),
      );
    }
  }
}
final CarpoolDetailPageProvider = StateNotifierProvider<CarpoolDetailPageViewModel, CardViewState>(
    (ref) => CarpoolDetailPageViewModel(ref.read(carpoolRepositoryProvider)),
);