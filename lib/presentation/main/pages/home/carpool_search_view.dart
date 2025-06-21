import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cba_connect_application/presentation/main/pages/home/destination_selection_view.dart';
import 'package:cba_connect_application/models/carpool_room.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:cba_connect_application/presentation/main/pages/home/carpool_detail_page_view.dart';
import 'package:cba_connect_application/presentation/main/pages/home/card_detail_view.dart';
import 'package:cba_connect_application/presentation/widgets/loading_spinner_view.dart';
import 'package:intl/intl.dart';
import 'carpool_search_view_model.dart';


class CarpoolSearchView extends ConsumerStatefulWidget {
  /** 매 수련회마다 바꿔주기*/
  static const RETREAT_ADDRESS = '경기도 양주시 광적면 현석로 313-44';

  const CarpoolSearchView({Key? key}) : super(key: key);

  @override
  ConsumerState<CarpoolSearchView> createState() => _CarpoolSearchViewState();
}

class _CarpoolSearchViewState extends ConsumerState<CarpoolSearchView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> tabLabels = ['수련회장으로', '집으로'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabLabels.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(carpoolSearchProvider.notifier).fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(carpoolSearchProvider);
    final keyword = _searchController.text.toLowerCase();

    final rooms = state.rooms.where((room) {
      final o = room.origin.toLowerCase();
      final d = room.destination.toLowerCase();
      return o.contains(keyword) || d.contains(keyword);
    }).toList();

    final keywordFiltered = state.rooms.where((room) {
      final o = room.origin.toLowerCase();
      final d = room.destination.toLowerCase();
      return o.contains(keyword) || d.contains(keyword);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset('assets/images/search_icon.png', width: 24, height: 24),
            SizedBox(width: 8),
            Text('카풀 찾아보기',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationSelectionView())),
              style: TextButton.styleFrom(
                side: const BorderSide(color: Colors.black87),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('+ 카풀 등록', style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.deepPurple,
                labelColor: Colors.black,
                indicatorWeight: 3,
                tabs: tabLabels.map((t) => Tab(text: t)).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: () {
        switch (state.status) {
          case CarpoolSearchStatus.loading:
            return const Center(child: LoadingSpinnerView(isLoading: true));
          case CarpoolSearchStatus.error:
            return Center(child: Text(state.message ?? '에러가 발생했습니다.'));
          case CarpoolSearchStatus.success:
          case CarpoolSearchStatus.initial:
            return TabBarView(
              controller: _tabController,
              children: List.generate(tabLabels.length, (tabIndex) {
                final tabFiltered = keywordFiltered.where((room) {
                  if (tabIndex == 0) {
                    return room.destination.contains(CarpoolSearchView.RETREAT_ADDRESS);
                  } else {
                    return room.origin.contains(CarpoolSearchView.RETREAT_ADDRESS);
                  }
                }).toList();

                return _buildTabContent(tabFiltered, tabIndex);
              }),
            );
        }
      }(),
    );
  }

  Widget _buildTabContent(List<CarpoolRoom> rooms, int tabIndex) {
    // 1) raw keyword
    final raw = _searchController.text.trim();
    // 2) headerText 결정
    final headerText = raw.isNotEmpty
        ? "[$raw]에 대한 카풀 목록"
        : (tabIndex == 0
        ? '어디서 출발하나요?'
        : '어디로 가나요?');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            headerText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        // 검색창
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '지역 검색(강남, 마포, 신도림)',
                      hintStyle: const TextStyle(color: Colors.black38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Divider(thickness: 3),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text.rich(
            TextSpan(
              text: '현재 ',
              children: [
                TextSpan(
                  text: '[${rooms.length}]개',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '의 카풀이 등록되어 있습니다.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: rooms.length,
            itemBuilder: (context, i) {
              final room = rooms[i];
              final current = room.seatsTotal - room.seatsLeft;
              final timeText = DateFormat('a h시 mm분', 'ko').format(room.departureTime);

              final regionValue = tabIndex == 0
                  ? room.origin
                  : room.destination;
              final locationValue = tabIndex == 0
                  ? (room.originDetailed ?? '')
                  : '';

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarpoolDetailPageView(
                      id: room.id,
                      tabIndex: tabIndex,
                    ),
                  ),
                ),
                child: CardDetailView(
                  name: room.driver.name,
                  region: regionValue,
                  totalPeople: room.seatsTotal,
                  currentPeople: current,
                  carInfo: room.carInfo ?? '',
                  time: timeText,
                  location: locationValue,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}