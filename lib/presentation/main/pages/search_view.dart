import 'package:cba_connect_application/presentation/chat/carpool_detail_popup.dart';
import 'package:flutter/material.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    // 임시 카풀 리스트
    final dummyList = List.generate(5, (i) => i + 1);

    return ListView.builder(
      itemCount: dummyList.length,
      itemBuilder: (context, index) {
        final roomId = dummyList[index];
        return ListTile(
          title: Text('카풀 $roomId'),
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (_) => Dialog(
                    insetPadding: EdgeInsets.symmetric(horizontal: 32),
                    child: CarpoolDetailPopup(roomId: roomId),
                  ),
            );
          },
        );
      },
    );
  }
}
