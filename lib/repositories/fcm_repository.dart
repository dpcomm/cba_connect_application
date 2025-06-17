import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../datasources/fcm_data_source.dart';
import '../dto/regist_fcm_dto.dart';
import '../models/fcmToken.dart';

abstract class FcmRepository {
  Future<FcmToken> registToken(RegistFcmDto dto);
}

class FcmRepositoryImpl implements FcmRepository {
  final FcmDataSource _ds;
  FcmRepositoryImpl(this._ds);

  @override
  Future<FcmToken> registToken(RegistFcmDto dto) {
    print("fcm repository regist token");
    return _ds.regist(dto);
  }

}
