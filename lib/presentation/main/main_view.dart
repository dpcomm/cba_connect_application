import 'package:cba_connect_application/core/color.dart';
import 'package:cba_connect_application/presentation/main/pages/home/home_view.dart';
import 'package:cba_connect_application/presentation/main/pages/mycarpool/mycarpool_view.dart';
import 'package:cba_connect_application/presentation/main/pages/setting/setting_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  /** 임의로 테스트하려고 주석처리 해놨습니다!*/
  // final List<Widget> _views = [CarpoolSearchView(), SearchView(), ProfileView()];
  final List<Widget> _views = [CarpoolSearchView(), MyCarpoolView(), SettingView()];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _views.length, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idx = _tabController.index;
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('카풀 서비스'),
      //   backgroundColor: Colors.white,
      // ),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.transparent,
            labelColor: secondaryColor,
            tabs: <Widget>[
              Tab(
                icon: Icon(idx == 0 ? Icons.home : Icons.home_outlined),
                text: '홈',
              ),
              Tab(
                icon: Icon(idx == 1 ? Icons.search : Icons.search_outlined),
                text: '마이카풀',
              ),
              Tab(
                icon: Icon(idx == 2 ? Icons.person : Icons.person_outline),
                text: '설정',
              ),
            ],
          ),
        )
      ),
      body: TabBarView(
        controller: _tabController,
        children: _views,
      ),
    );
  }
}
