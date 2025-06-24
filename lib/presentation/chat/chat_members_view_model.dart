import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/repositories/carpool_repository.dart';
import 'package:cba_connect_application/presentation/main/pages/home/registration/registration_view_model.dart';

enum CarpoolMembersStatus { initial, loading, success, error }

class CarpoolMembersState {
  final CarpoolMembersStatus status;
  final List<CarpoolUserInfo> members;
  final String? message;

  const CarpoolMembersState({
    this.status = CarpoolMembersStatus.initial,
    this.members = const [],
    this.message,
  });

  CarpoolMembersState copyWith({
    CarpoolMembersStatus? status,
    List<CarpoolUserInfo>? members,
    String? message,
  }) {
    return CarpoolMembersState(
      status: status ?? this.status,
      members: members ?? this.members,
      message: message ?? this.message,
    );
  }
}

class CarpoolMembersViewModel extends StateNotifier<CarpoolMembersState> {
  final int roomId;
  final CarpoolRepository _carpoolRepository;
  final Ref ref;

  CarpoolMembersViewModel({
    required this.roomId,
    required CarpoolRepository carpoolRepository,
    required this.ref,
  })  : _carpoolRepository = carpoolRepository,
        super(const CarpoolMembersState());

  Future<void> loadMembers() async {
    state = state.copyWith(status: CarpoolMembersStatus.loading);
    try {
      final roomDetail = await _carpoolRepository.fetchCarpoolDetails(roomId);

      if (!mounted) {
        // 만약 ViewModel이 dispose되었다면, 더 이상 상태를 업데이트하지 않고 함수 종료
        print('[CarpoolMembersViewModel] loadMembers: ViewModel is not mounted. Skipping state update.');
        return;
      }

      final members = <CarpoolUserInfo>[
        ...roomDetail.members.map((m) => CarpoolUserInfo(
              userId: m.userId,
              name: m.name,
              phone: m.phone ?? '',
            )),
      ];

      state = CarpoolMembersState(
        status: CarpoolMembersStatus.success,
        members: members,
      );
    } catch (e) {

      if (!mounted) {
        print('[CarpoolMembersViewModel] loadMembers: ViewModel is not mounted. Skipping error state update.');
        return;
      }
      
      state = CarpoolMembersState(
        status: CarpoolMembersStatus.error,
        message: e.toString(),
      );
    }
  }
}

// 프로바이더 선언 (roomId 별)
final carpoolMembersProvider = StateNotifierProvider.family
    .autoDispose<CarpoolMembersViewModel, CarpoolMembersState, int>((ref, roomId) {
  final carpoolRepository = ref.watch(carpoolRepositoryProvider);
  return CarpoolMembersViewModel(
    roomId: roomId,
    carpoolRepository: carpoolRepository,
    ref: ref,
  );
});
