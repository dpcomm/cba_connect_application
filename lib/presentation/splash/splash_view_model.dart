import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cba_connect_application/repositories/consent_repository.dart';
import 'package:cba_connect_application/datasources/consent_data_source.dart';
import 'package:cba_connect_application/models/consent.dart';
import 'package:cba_connect_application/core/custom_exception.dart';

enum ConsentStatus { initial, loading, agreed, needsConsent, error }

class ConsentState {
  final ConsentStatus status;
  final String? message;
  final Consent? consent;

  ConsentState({this.status = ConsentStatus.initial, this.message, this.consent});
}

class ConsentViewModel extends StateNotifier<ConsentState> {
  final ConsentRepository _consentRepo;

  ConsentViewModel(this._consentRepo) : super(ConsentState());

  Future<bool> checkUserConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final isConsent = prefs.getBool('consentPrivacyPolicy') ?? false;
    print(isConsent);
    return isConsent;
  }
}

final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  return ConsentRepositoryImpl(ConsentDataSourceImpl());
});

final splashViewModelProvider =
  StateNotifierProvider<ConsentViewModel, ConsentState>((ref) {
  final repo = ref.read(consentRepositoryProvider);
  return ConsentViewModel(repo);
});