import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/presentation/main/pages/home/registration/registration_view_model.dart';

// AsyncNotifier 구현
class CarpoolMembersNotifier extends AutoDisposeFamilyAsyncNotifier<List<CarpoolUserInfo>, int> {

  @override
  Future<List<CarpoolUserInfo>> build(int roomId) async {
    final carpoolRepository = ref.watch(carpoolRepositoryProvider);
    final roomDetail = await carpoolRepository.fetchCarpoolDetails(roomId);

    final members = roomDetail.members.map((m) => CarpoolUserInfo(
      userId: m.userId,
      name: m.name,
      phone: m.phone ?? '',
    )).toList();

    return members;
  }

  // 필요한 경우 외부에서 데이터를 새로고침하는 메서드
  Future<void> refreshMembers() async {
    // state를 AsyncLoading으로 설정하여 로딩 상태를 알리고
    // build 메서드를 다시 호출하여 데이터를 새로고침
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(arg)); // arg는 build 메서드의 roomId 값
  }
}

// AsyncNotifierProvider 선언
final carpoolMembersProvider = AsyncNotifierProvider.family
    .autoDispose<CarpoolMembersNotifier, List<CarpoolUserInfo>, int>(() {
  return CarpoolMembersNotifier();
});