import 'package:cba_connect_application/presentation/main/pages/mycarpool/mycarpool_detail_page/mycarpool_detail_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cba_connect_application/core/color.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:cba_connect_application/presentation/main/pages/mycarpool/mycarpool_view_model.dart';
import 'package:cba_connect_application/presentation/login/login_view_model.dart';

class MyCarpoolView extends ConsumerStatefulWidget {
  const MyCarpoolView({Key? key}) : super(key: key);

  @override
  ConsumerState<MyCarpoolView> createState() => _MyCarpoolViewState();
}

class _MyCarpoolViewState extends ConsumerState<MyCarpoolView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 수련회장 주소 정의 (상수로 관리)
  static const String RETREAT_FULL_ADDRESS = '경기도 양주시 광적면 현석로 313-44';
  static const String RETREAT_DISPLAY_NAME = '수련회장';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 전체, 진행중, 완료
    _tabController.addListener(_onTabChanged); // 탭 변경 리스너 추가

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMyCarpools();
    });
  }

  void _fetchMyCarpools() {
    final loginState = ref.read(loginViewModelProvider);
    if (loginState.status == LoginStatus.success && loginState.user != null) {
      final userId = loginState.user!.id;
      ref.read(myCarpoolProvider.notifier).fetchMyCarpools(userId);
    } else {
      // 사용자가 로그인되어 있지 않은 경우 처리
      // 예: 로그인 페이지로 이동 또는 에러 메시지 표시
      print('User not logged in. Cannot fetch my carpools.');
      // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginView()));
    }
  }

  void _onTabChanged() {
    // 탭이 변경될 때마다 화면을 갱신하여 필터링된 리스트 보여줌.
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myCarpoolProvider);
    final loginState = ref.watch(loginViewModelProvider);

    // 로그인 상태 확인
    if (loginState.status != LoginStatus.success || loginState.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('마이 카풀', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('로그인이 필요합니다.'),
        ),
      );
    }

    // 카풀 목록 필터링
    List<CarpoolRoom> filteredRooms = [];
    if (state.status == CarpoolListStatus.success) {
      final allMyRooms = state.rooms;
      switch (_tabController.index) {
        case 0: // 전체
          filteredRooms = allMyRooms;
          break;
        case 1: // 진행중
          filteredRooms = allMyRooms.where((room) => room.status != CarpoolStatus.arrived).toList();
          break;
        case 2: // 완료
          filteredRooms = allMyRooms.where((room) => room.status == CarpoolStatus.arrived).toList();
          break;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,     
        surfaceTintColor: Colors.transparent, 
        scrolledUnderElevation: 0,          
        centerTitle: false,
        titleSpacing: 16, // 좌측 여백
        title: Row(
          mainAxisSize: MainAxisSize.min, // Row의 크기를 자식 위젯에 맞게 최소화
          children: [
            Icon(Icons.directions_car),
            SizedBox(width: 8), // 아이콘과 텍스트 사이 간격
            Text(
              '마이 카풀',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight), // 탭바 높이
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  height: 40, // 탭바 높이
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.0,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: secondaryColor, // 선택된 탭 배경색
                    ),
                    labelColor: Colors.white, // 선택된 탭 글자색
                    unselectedLabelColor: Colors.black54, // 선택되지 않은 탭 글자색
                    tabs: const [
                      Tab(text: '전체'),
                      Tab(text: '진행중'),
                      Tab(text: '완료'),
                    ],
                  ),
                ),
                const SizedBox(height: 10), // 탭바와 아래 컨텐츠 사이 간격
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                '카풀 내역',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: () {
                switch (state.status) {
                  case CarpoolListStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case CarpoolListStatus.error:
                    return Center(child: Text(state.message ?? '내 카풀 목록을 불러오는데 에러가 발생했습니다.'));
                  case CarpoolListStatus.success:
                  case CarpoolListStatus.initial:
                    if (filteredRooms.isEmpty) {
                        String emptyMessage;
                        switch (_tabController.index) {
                          case 0: // 전체
                            emptyMessage = '마이 카풀 내역이 없습니다.';
                            break;
                          case 1: // 진행중
                            emptyMessage = '진행중인 카풀이 없습니다.';
                            break;
                          case 2: // 완료
                            emptyMessage = '완료된 카풀이 없습니다.';
                            break;
                          default:
                            emptyMessage = '마이 카풀 내역이 없습니다.'; // 기본값
                        }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(emptyMessage, style: TextStyle(fontSize: 16, color: text600Color)),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, i) {
                        final room = filteredRooms[i];
                        final timeText = DateFormat('M/d(E) a h:mm', 'ko').format(room.departureTime);
                        
                        // 주소 텍스트 대체 로직 추가
                        final displayOrigin = room.origin == RETREAT_FULL_ADDRESS ? RETREAT_DISPLAY_NAME : room.origin;
                        final displayDestination = room.destination == RETREAT_FULL_ADDRESS ? RETREAT_DISPLAY_NAME : room.destination;
                        
                        final bool isOriginRetreat = room.origin == RETREAT_FULL_ADDRESS;
                        final bool isDestinationRetreat = room.destination == RETREAT_FULL_ADDRESS;

                        final statusText = room.status == CarpoolStatus.arrived ? '완료' : '진행중';
                        final statusColor = room.status == CarpoolStatus.arrived ? text700Color : secondaryColor;
                        final statusBackgroundColor = room.status == CarpoolStatus.arrived ? text500Color! :secondaryColor.withOpacity(0.1);

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyCarpoolDetailPageView(id: room.id),
                            ),
                          ),
                          child: MyCarpoolListItem(
                            origin: displayOrigin,
                            destination: displayDestination,
                            departureTime: timeText,
                            driverName: room.driver.name,
                            statusText: statusText,
                            statusColor: statusColor,
                            statusBackgroundColor: statusBackgroundColor,
                            isOriginRetreat: isOriginRetreat, 
                            isDestinationRetreat: isDestinationRetreat,
                          ),
                        );
                      },
                    );
                }
              }(),
            ),
          ],
        ),
      ),
    );
  }
}

// 이미지에 맞춰 새로운 카풀 리스트 아이템 위젯 생성
class MyCarpoolListItem extends StatelessWidget {
  final String origin;
  final String destination;
  final String departureTime;
  final String driverName;
  final String statusText;
  final Color statusColor;
  final Color statusBackgroundColor;
  final bool isOriginRetreat;
  final bool isDestinationRetreat;

  const MyCarpoolListItem({
    Key? key,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.driverName,
    required this.statusText,
    required this.statusColor,
    required this.statusBackgroundColor,
    required this.isOriginRetreat,     
    required this.isDestinationRetreat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 1.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌측 아이콘(도착지따라 구분)         
          Row(
            children: [
              if (isOriginRetreat) // 출발지가 수련회장인 경우
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: secondarySub2Color,
                    // color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset('assets/images/home.png',),
                ),
              if (isOriginRetreat && isDestinationRetreat) // 출발지와 도착지 모두 수련회장인 경우 간격 추가
                const SizedBox(width: 4),
              if (isDestinationRetreat) // 도착지가 수련회장인 경우
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primarySub2Color,
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset('assets/images/retreat.png'),
                ),
              if (!isOriginRetreat && !isDestinationRetreat) // 둘 다 수련회장이 아닌 경우 기본 아이콘
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    // color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.house, color: Colors.grey[600]), // 기본 집 아이콘
                ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      origin,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_right_alt, size: 20),
                    Text(
                      destination,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    // 상태 칩
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBackgroundColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '출발시간 : $departureTime',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 6),
                Text(
                  '운전자 : $driverName',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}