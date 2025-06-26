import 'package:cba_connect_application/presentation/chat/chat_view.dart';
import 'package:cba_connect_application/presentation/main/pages/home/carpool_edit/carpool_edit_view.dart';
import 'package:cba_connect_application/presentation/main/pages/mycarpool/mycarpool_detail_page/mycarpool_detail_page_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kakao_map_native/kakao_map_native_view.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/models/user.dart';
import '../../home/carpool_detail_page/carpool_detail_page_view_model.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';
import 'package:cba_connect_application/core/color.dart';
import 'package:cba_connect_application/core/phone_utils.dart';

const Widget H_Space4 = SizedBox(height: 4.0);
const Widget H_Space8 = SizedBox(height: 8.0);
const Widget H_Space12 = SizedBox(height: 12.0);
const Widget H_Space16 = SizedBox(height: 16.0);
const Widget H_Space20 = SizedBox(height: 20.0);
const Widget H_Space24 = SizedBox(height: 24.0);

class MyCarpoolDetailPageView extends ConsumerStatefulWidget {
  final int id; // roomId
  const MyCarpoolDetailPageView({Key? key, required this.id}) : super(key: key);

  @override
  ConsumerState<MyCarpoolDetailPageView> createState() => _MyCarpoolDetailPageViewState();
}

class _MyCarpoolDetailPageViewState extends ConsumerState<MyCarpoolDetailPageView> {
  final GlobalKey<KakaoMapNativeViewState> _mapKey = GlobalKey();
  late bool _isDriver; // 현재 로그인 유저가 이 카풀의 '운전자'인지 여부
  int? _currentUserId; // 현재 로그인한 사용자 ID

  @override
  void initState() {
    super.initState();
    _isDriver = false;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loginState = ref.read(loginViewModelProvider);
      if (loginState.status == LoginStatus.success && loginState.user != null) {
        _currentUserId = loginState.user!.id;
      } else {
        print('User not logged in. Cannot determine driver/passenger status.');
        // 사용자에게 메시지 표시 후 이전 화면으로 돌아가기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        Navigator.of(context).pop(); // 이전 페이지로 돌아가기
        return;
      }

      await ref.read(myCarpoolDetailPageProvider.notifier).fetchCarpoolDetail(widget.id);

      final state = ref.read(myCarpoolDetailPageProvider);
      if (state.status == MyCarpoolDetailStatus.success && state.roomDetail != null && _currentUserId != null) {
        setState(() {
          _isDriver = state.roomDetail!.room.driver.id == _currentUserId; 
        });
      }
    });
  }

  Future<void> _leaveCarpool() async {

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('카풀 나가기'),
        content: const Text('정말 카풀에서 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (shouldLeave != true) return;

    if (_currentUserId != null) {
      ref.read(myCarpoolDetailPageProvider.notifier).leaveCarpool(_currentUserId!, widget.id).then((_) {
        final state = ref.read(myCarpoolDetailPageProvider);
        if (state.status == MyCarpoolDetailStatus.left) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카풀에서 나갔습니다.')),
          );
          Navigator.of(context).pop();
        } else if (state.status == MyCarpoolDetailStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message ?? '카풀 나가기에 실패했습니다.')),
          );
        }
      });
    }
   }

  Future<void> _cancelCarpoolRegistration() async {
    print('카풀 삭제: roomId=${widget.id}');

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('카풀 삭제'),
        content: const Text('정말 카풀을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    if (_currentUserId != null) {
      ref.read(myCarpoolDetailPageProvider.notifier).deleteCarpool(widget.id).then((_) {
        final state = ref.read(myCarpoolDetailPageProvider);
        if (state.status == MyCarpoolDetailStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카풀이 삭제되었습니다.')),
          );
          Navigator.of(context).pop(); // 성공 시 이전 페이지로 돌아가기
        } else if (state.status == MyCarpoolDetailStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message ?? '카풀 삭제에 실패했습니다.')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myCarpoolDetailPageProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false, // 왼쪽 정렬 위함
        actionsPadding: EdgeInsets.only(right: 24.0),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          state.status == MyCarpoolDetailStatus.success
              ? '카풀 상세 내용'
              // ? '${state.roomDetail!.room.driver.name}님의 카풀 정보'
              : '카풀 정보',
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        leading: const BackButton(),
        actions: [
          if (state.status == MyCarpoolDetailStatus.success && _isDriver)
            TextButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarpoolEditView(
                      carpoolId: state.roomDetail!.room.id,
                      destinationType: state.roomDetail!.room.destination == "경기도 양주시 광적면 현석로 313-44" ? 'retreat' : 'home',
                    ),
                  ),
                );

                if (result == true) {
                  await ref.read(myCarpoolDetailPageProvider.notifier).fetchCarpoolDetail(widget.id);
                  // setState(() {}); // 필요 시 리렌더링
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: secondaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                minimumSize: Size(0, 0), // 최소 크기 제거
                tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 터치 영역 크기를 내용물에 맞게 줄임
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                ),
                
                
              ),
              child: const Text(
                '수정',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: state.status == MyCarpoolDetailStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : state.status == MyCarpoolDetailStatus.error
              ? Center(child: Text(state.message ?? '에러가 발생했습니다.'))
              : (state.status == MyCarpoolDetailStatus.left || state.status == MyCarpoolDetailStatus.deleted)
                  ? Center(child: Text(state.message ?? '작업이 완료되었습니다.')) // 작업 완료 후 메시지 표시
                  : (state.status == MyCarpoolDetailStatus.success && state.roomDetail != null)
                      ? _buildDetailUI(state.roomDetail!)
                      : const Center(child: Text('카풀 정보를 불러올 수 없습니다.')), // 초기 상태 또는 데이터 없음
    );
  }

  Widget _buildDetailUI(CarpoolRoomDetail roomDetail) {
    final int driverId = roomDetail.room.driver.id;
    final List<CarpoolUserInfo> passengers = roomDetail.members.where((member) => member.userId != driverId).toList();

    final mapLat = roomDetail.room.originLat;
    final mapLng = roomDetail.room.originLng;

    final originRaw = roomDetail.room.origin;
    final originText = originRaw.isEmpty
        ? '출발지 정보 없음'
        : (originRaw == "경기도 양주시 광적면 현석로 313-44" ? "수련회장" : originRaw);

    final destinationRaw = roomDetail.room.destination;
    final destinationText = destinationRaw.isEmpty
        ? '도착지 정보 없음'
        : (destinationRaw == "경기도 양주시 광적면 현석로 313-44" ? "수련회장" : destinationRaw);

    final timeText = DateFormat('M/d(E) a h:mm', 'ko').format(roomDetail.room.departureTime);

    return SingleChildScrollView(
      child: 
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '경로',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            H_Space8,
            _buildPathRow(Icons.directions_car, '출발', originText),
            H_Space4,
            const Divider(thickness: 1, height: 1), 
            H_Space4,
            _buildPathRow(Icons.location_on, '도착', destinationText),
            H_Space4,
            const Divider(thickness: 1, height: 1), 
            H_Space20,

            const Text(
              '카풀 일정',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            H_Space8,
            _buildInfoRow(
              Icons.calendar_today,
              '날짜 및 시간',
              timeText,
            ),
            H_Space4,
            const Divider(thickness: 1, height: 1),
            H_Space20,

            _buildDriverInfo(roomDetail.room.driver, roomDetail.room.carInfo),
            H_Space8,

            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return KakaoMapNativeView(
                      key: _mapKey,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      latitude: mapLat,
                      longitude: mapLng,
                      zoomLevel: 15,
                      mapType: 'map',
                      overlay: 'hill_shading',
                    );
                  },
                ),
              ),
            ),
            H_Space20,
            const Text(
              '탑승자 목록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            H_Space8,
            if (passengers.isEmpty)
              const Text('아직 탑승자가 없습니다.', style: TextStyle(color: Colors.grey))
            else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 필요에 따라 정렬 설정
                children: [
                  ...passengers.map((member) => _buildPassengerInfo(
                      member.name,
                      member.phone,
                    )).toList(),
                ],
              ),
            ],
          
            H_Space4,
            const Divider(thickness: 1, height: 1),
            H_Space20,

            const Text(
              '메모',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            H_Space4,
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(Icons.sticky_note_2, color: Colors.grey.shade700, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        roomDetail.room.note.isEmpty ? "메모가 없습니다" : roomDetail.room.note,
                        style: const TextStyle(fontSize: 14, color: text900Color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            H_Space4,
            const Divider(thickness: 1, height: 1),
            H_Space20,

            _buildBottomButtons(roomDetail),
          ],
        ),
      ),
    );
  }

  Widget _buildPathRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            child: Icon(icon, color: Colors.grey.shade700, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: text900Color)),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, color: Colors.grey.shade700, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfo(Driver driver, String carInfo) {
    return Row(
      children: [
        const CircleAvatar(radius: 25),
        const SizedBox(width: 12),
        Expanded(  // 공간 남으면 텍스트 줄바꿈 가능하게 확장
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      driver.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                  onTap: () => makePhoneCall(context, driver.phone),
                    child: Container(
                      decoration: BoxDecoration(
                        color: secondarySub2Color,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: const Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  )
                ],
              ),
              Text(
                '운전자 ${driver.phone.isEmpty ? '연락처 없음' : driver.phone} | $carInfo',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerInfo(String name, String phoneNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // const CircleAvatar(radius: 18)
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.person, color: Colors.grey.shade700, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(name, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 12),
                Text(
                  phoneNumber,
                  style: const TextStyle(fontSize: 14, color: text700Color),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => makePhoneCall(context, phoneNumber),
                  child: Container(
                    decoration: BoxDecoration(
                      color: secondarySub2Color,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(CarpoolRoomDetail room) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0), // 하단 마진 추가
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (_isDriver) {
                  _cancelCarpoolRegistration();
                } else {
                  _leaveCarpool();
                }
              },
              child: Text(
                _isDriver ? '카풀 삭제하기' : '카풀 나가기',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                backgroundColor: secondarySub1Color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatView(
                      roomId: room.room.id,
                    ),
                  ),
                );
              },
              child: const Text(
                '메시지',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}