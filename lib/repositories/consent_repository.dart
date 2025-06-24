import '../core/custom_exception.dart';
import '../datasources/consent_data_source.dart';
import '../models/consent.dart';

abstract class ConsentRepository {
  Future<Consent> fetchConsent(int userId, String consentType);
  Future<void> createConsent({required int userId, required String consentType, required bool value});
}

class ConsentRepositoryImpl implements ConsentRepository {
  final ConsentDataSource _dataSource;

  ConsentRepositoryImpl(this._dataSource);

  @override
  Future<Consent> fetchConsent(int userId, String consentType) async {
    try {
      return await _dataSource.fetchConsentByUserIdAndConsentType(userId, consentType);
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw UnknownException('동의 정보 조회 중 알 수 없는 오류: ${e.toString()}');
    }
  }

  @override
  Future<void> createConsent({required int userId, required String consentType, required bool value}) async {
    try {
      await _dataSource.createConsent(userId: userId, consentType: consentType, value: value);
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw UnknownException('동의 정보 생성 중 알 수 없는 오류: ${e.toString()}');
    }
  }
}