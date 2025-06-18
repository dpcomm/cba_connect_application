import 'package:cba_connect_application/dto/delete_fcm_token_dto.dart';
import 'package:cba_connect_application/dto/refresh_fcm_token_dto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../datasources/fcm_data_source.dart';
import '../dto/regist_fcm_dto.dart';
import '../models/fcmToken.dart';

abstract class FcmRepository {
  Future<FcmToken> registToken(RegistFcmDto dto);
  Future<FcmToken> deleteToken(DeleteFcmTokenDto dto);
  Future<FcmToken> refreshToken(RefreshFcmTokenDto dto);
}

class FcmRepositoryImpl implements FcmRepository {
  final FcmDataSource _ds;
  FcmRepositoryImpl(this._ds);

  @override
  Future<FcmToken> registToken(RegistFcmDto dto) {
    print("fcm repository regist token");
    return _ds.regist(dto);
  }

  @override
  Future<FcmToken> deleteToken(DeleteFcmTokenDto dto) {
    print("fcm repository delete token");
    return _ds.delete(dto);
  }
  
  @override
  Future<FcmToken> refreshToken(RefreshFcmTokenDto dto) {
    print("fcm repository refresh token");
    return _ds.refresh(dto);
  }  
}
