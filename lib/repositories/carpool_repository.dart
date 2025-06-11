import '../datasources/carpool_data_source.dart';
import '../dto/create_carpool_dto.dart';
import '../models/carpool_room.dart';

abstract class CarpoolRepository {
  Future<CarpoolRoom> createCarpool(CreateCarpoolDto dto);
}

class CarpoolRepositoryImpl implements CarpoolRepository {
  final CarpoolDataSource _ds;
  CarpoolRepositoryImpl(this._ds);

  @override
  Future<CarpoolRoom> createCarpool(CreateCarpoolDto dto) {
    return _ds.create(dto);
  }
}
