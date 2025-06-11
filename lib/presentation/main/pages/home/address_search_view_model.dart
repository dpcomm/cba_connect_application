// lib/view_models/address_search_view_model.dart

import 'dart:async';
import 'package:cba_connect_application/core/custom_exception.dart';
import 'package:cba_connect_application/datasources/address_data_source.dart';
import 'package:cba_connect_application/repositories/address_repository.dart';
import 'package:cba_connect_application/models/address_result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddressSearchState {
  final bool loading;
  final List<AddressResult> results;
  final String? error;
  const AddressSearchState({
    this.loading = false,
    this.results = const [],
    this.error,
  });
}

class AddressSearchViewModel
    extends StateNotifier<AddressSearchState> {
  AddressSearchViewModel(this._repo) : super(const AddressSearchState());

  final AddressRepository _repo;
  Timer? _debounce;

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty) {
        state = const AddressSearchState();
        return;
      }
      state = const AddressSearchState(loading: true);

      try {
        final list = await _repo.search(query);
        state = AddressSearchState(results: list);
      } on NetworkException catch (e) {
        state = AddressSearchState(error: e.toString());
      } catch (e) {
        state = AddressSearchState(error: '알 수 없는 오류');
      }
    });
  }
}

final addressDataSourceProvider = Provider<AddressDataSource>(
      (ref) => AddressDataSourceImpl(),
);

final addressRepositoryProvider = Provider<AddressRepository>(
      (ref) => AddressRepositoryImpl(ref.read(addressDataSourceProvider)),
);

final addressSearchProvider = StateNotifierProvider<
    AddressSearchViewModel, AddressSearchState>(
      (ref) => AddressSearchViewModel(ref.read(addressRepositoryProvider)),
);