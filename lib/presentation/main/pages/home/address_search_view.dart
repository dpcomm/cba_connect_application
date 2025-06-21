import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'address_search_view_model.dart';
import 'package:cba_connect_application/models/address_result.dart';

Future<AddressResult?> showAddressSearchBottomSheet(BuildContext context) {
  return showModalBottomSheet<AddressResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _AddressSearchSheet(),
  );
}

class _AddressSearchSheet extends ConsumerWidget {
  const _AddressSearchSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressSearchProvider);
    final vm = ref.read(addressSearchProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              hintText: '주소를 입력하세요',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: vm.search,
          ),
          const SizedBox(height: 12),
          if (state.loading) const CircularProgressIndicator(),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: state.results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = state.results[i];
                return ListTile(
                  title: Text(r.address),
                  onTap: () => Navigator.pop(context, r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
