import '../datasources/address_data_source.dart';
import '../models/address_result.dart';
import '../core/custom_exception.dart';

abstract class AddressRepository {
  Future<List<AddressResult>> search(String query);
}

class AddressRepositoryImpl implements AddressRepository {
  final AddressDataSource _dataSource;
  AddressRepositoryImpl(this._dataSource);

  @override
  Future<List<AddressResult>> search(String query) {
    return _dataSource.searchAddresses(query);
  }
}
