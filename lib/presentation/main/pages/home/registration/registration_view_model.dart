import 'package:cba_connect_application/datasources/carpool_data_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/dto/create_carpool_dto.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart';
import 'package:cba_connect_application/core/custom_exception.dart';

enum RegistrationStatus { initial, loading, success, error }

class RegistrationState {
  final RegistrationStatus status;
  final CarpoolRoom? room;
  final String? message;

  const RegistrationState({
    this.status = RegistrationStatus.initial,
    this.room,
    this.message,
  });
}

class RegistrationViewModel
    extends StateNotifier<RegistrationState> {
  RegistrationViewModel(this._repo)
      : super(const RegistrationState());

  final CarpoolRepository _repo;

  Future<void> createCarpool(CreateCarpoolDto dto) async {
    state = const RegistrationState(status: RegistrationStatus.loading);
    try {
      final room = await _repo.createCarpool(dto);
      print(room);
      state = RegistrationState(
        status: RegistrationStatus.success,
        room: room,
      );
    } on NetworkException catch (e) {
      state = RegistrationState(
        status: RegistrationStatus.error,
        message: e.toString(),
      );
    } catch (e) {
      print(e);
      state = RegistrationState(
        status: RegistrationStatus.error,
        message: '알 수 없는 오류',
      );
    }
  }
}

final carpoolDataSourceProvider = Provider<CarpoolDataSource>(
      (ref) => CarpoolDataSourceImpl(),
);

final carpoolRepositoryProvider = Provider<CarpoolRepository>(
      (ref) => CarpoolRepositoryImpl(ref.read(carpoolDataSourceProvider)),
);

final registrationViewModelProvider =
StateNotifierProvider<RegistrationViewModel, RegistrationState>(
      (ref) => RegistrationViewModel(ref.read(carpoolRepositoryProvider)),
);