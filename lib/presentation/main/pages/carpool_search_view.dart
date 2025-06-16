import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:cba_connect_application/presentation/widgets/card_view.dart';
import 'package:cba_connect_application/presentation/main/pages/card_detail_view.dart';
import 'package:cba_connect_application/presentation/main/pages/destination_selection_view.dart';
import 'package:cba_connect_application/presentation/main/pages/loading_spinner_view.dart';

class CarpoolSearchView extends StatefulWidget {
  const CarpoolSearchView({super.key});

  @override
  State<CarpoolSearchView> createState() => _CarpoolChatPageState();
}


class _CarpoolChatPageState extends State<CarpoolSearchView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredChatData = [];


  final List<String> tabLabels = ['수련회장으로', '집으로'];

  final List<Map<String, dynamic>> chatData = [
    {
      'name': '박예림',
      'region': '부평',
      'currentPeople': 1,
      'maxPeople': 4,
      'car': '부가티',
      'carColor': '보라색',
      'carNumber': '97가1128',
      'time': '저녁 8시',
      'location': '신도림역 2번 출구 앞',
      'phone': '010-5508-1689',
      'message':'늦지 않았으면 좋겠어요',
    },
    {
      'name': '최슬기',
      'region': '강동구',
      'currentPeople': 2,
      'maxPeople': 3,
      'car': '셀토스',
      'carColor': '하얀색',
      'carNumber': '23가2817',
      'time': '저녁 10시',
      'location': '강동역 2번 출구 앞',
      'phone': '010-5564-6658',
      'message':'주정차시 벌금 내주세요',
    },
    {
      'name': '전형진',
      'region': '강서구',
      'currentPeople': 4,
      'maxPeople': 4,
      'car': '미니쿠퍼',
      'carColor': '초록색',
      'carNumber': '81너3428',
      'time': '저녁 7시',
      'location': '신도림역 테크노마트 앞',
      'phone': '010-5564-6658',
      'message':'커피는 사랑입니다',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    filteredChatData = List.from(chatData);
  }

  void _performSearch() {
    String keyword = _searchController.text.toLowerCase();
    setState(() {
      filteredChatData = chatData
          .where((item) => item['region']!.toLowerCase().contains(keyword))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {

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
            Text('카풀 찾아보기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DestinationSelectionView(),
                  ),
                );
              },
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
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: tabLabels.map((label) => Tab(text: label)).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: List.generate(
              tabLabels.length,
                  (index) => _buildTabContent(tabLabels[index]),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildTabContent(String tabTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal:24),
          child: Text(
            '어디서 출발하시나요?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    color: Colors.grey[100], // 진한 회색 배경
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _performSearch();
                    },
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: '지역 검색(강남, 마포, 신도림)',
                      hintStyle: TextStyle(color: Colors.black38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 검색 아이콘 버튼
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    // 여기에 검색 실행 로직 넣기
                    _performSearch();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Divider(
            thickness: 3,
          ),
        ),
        // 🔵 등록 안내 텍스트
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text.rich(
              TextSpan(
                text: '현재 ',
                style: TextStyle(fontWeight: FontWeight.normal),
                children: [
                  TextSpan(
                    text: '[${filteredChatData.length}]개',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '의 카풀이 등록되어 있습니다.',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            )
        ),
        const SizedBox(height: 12),

        // 카드 리스트
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: filteredChatData.length,
            itemBuilder: (context, index) {
              final item = filteredChatData[index];
              // final current = item['currentPeople'] ?? 0;
              // final max = item['maxPeople'] ?? 0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardView(
                        name: item['name'] ?? '',
                        region: item['region'] ?? '',
                        phone: item['phone'] ?? '',
                        totalPeople: item['maxPeople'] ?? 0,
                        currentPeople: item['currentPeople'] ?? 0,
                        car: item['car'] ?? '',
                        carColor: item['carColor'] ?? '',
                        carNumber: item['carNumber'] ?? '',
                        time: item['time'] ?? '',
                        location: item['location'] ?? '',
                        message: item['message'] ?? '',
                      )
                    ),
                  );
                },
                child: CardDetailView(
                  name: item['name'] ?? '',
                  region: item['region'] ?? '',
                  totalPeople: item['maxPeople'] ?? 0,
                  currentPeople: item['currentPeople'] ?? 0,
                  car: item['car'] ?? '',
                  carColor: item['carColor'] ?? '',
                  carNumber: item['carNumber'] ?? '',
                  time: item['time'] ?? '',
                  location: item['location'] ?? '',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

