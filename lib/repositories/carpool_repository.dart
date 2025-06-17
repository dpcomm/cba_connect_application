import '../datasources/carpool_data_source.dart';
import '../dto/create_carpool_dto.dart';
import '../models/carpool_room.dart';

abstract class CarpoolRepository {
  Future<CarpoolRoom> createCarpool(CreateCarpoolDto dto);
  Future<List<CarpoolRoom>> getAllCarpools();
  Future<CarpoolRoom> getCarpoolById(int id);
  Future<List<CarpoolRoom>> getMyCarpools(int userId);
  Future<void> joinCarpool({ required int userId, required int roomId });
  Future<void> leaveCarpool({ required int userId, required int roomId });
  Future<void> deleteCarpool(int roomId);
}

class CarpoolRepositoryImpl implements CarpoolRepository {
  final CarpoolDataSource _ds;
  CarpoolRepositoryImpl(this._ds);

  @override
  Future<List<CarpoolRoom>> getAllCarpools() {
    return _ds.fetchAll();
  }

  @override
  Future<CarpoolRoom> createCarpool(CreateCarpoolDto dto) {
    return _ds.create(dto);
  }

  @override
  Future<CarpoolRoom> getCarpoolById(int id) {
    return _ds.fetchById(id);
  }

  @override
  Future<List<CarpoolRoom>> getMyCarpools(int userId) {
    return _ds.fetchMyCarpools(userId);
  }

  @override
  Future<void> joinCarpool({ required int userId, required int roomId }) {
    return _ds.joinCarpool(userId, roomId);
  }

  @override
  Future<void> leaveCarpool({ required int userId, required int roomId }) {
    return _ds.leaveCarpool(userId, roomId);
  }

  @override
  Future<void> deleteCarpool(int roomId) {
    return _ds.deleteCarpool(roomId);
  }
}
