import 'package:cba_connect_application/presentation/chat/chat_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kakao_map_native/kakao_map_native_view.dart';
import 'package:cba_connect_application/presentation/widgets/button_view.dart';
import 'package:cba_connect_application/presentation/widgets/close_badge.dart';
import '../../../../login/login_view_model.dart';
import '../carpool_detail_page/carpool_detail_page_view_model.dart';

class CarpoolDetailPageView extends ConsumerStatefulWidget {
  final int id;
  final int tabIndex;

  const CarpoolDetailPageView({Key? key, required this.id, required this.tabIndex}) : super(key: key);

  @override
  ConsumerState<CarpoolDetailPageView> createState() => _CarpoolDetailPageState();
}

class _CarpoolDetailPageState extends ConsumerState<CarpoolDetailPageView> {
  final GlobalKey<KakaoMapNativeViewState> _mapKey = GlobalKey();
  late bool _isAppliedLocal;

  @override
  @override
  void initState() {
    super.initState();
    _isAppliedLocal = false;
    // 위젯 트리 빌드 완료 후에 fetch 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(CarpoolDetailPageProvider.notifier).fetchById(widget.id);
    });
  }
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(CarpoolDetailPageProvider);
    final viewModel = ref.read(CarpoolDetailPageProvider.notifier);
    final userId = ref.read(loginViewModelProvider).user!.id;

    Widget body;
    switch (state.status) {
      case CardViewStatus.initial:
      case CardViewStatus.loading:
        body = const Center(child: CircularProgressIndicator());
        break;
      case CardViewStatus.error:
        body = Center(child: Text(state.message ?? '에러가 발생했습니다.'));
        break;
      case CardViewStatus.success:
      case CardViewStatus.applied:
        body = _buildDetailUI(state, viewModel, userId);
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          state.status == CardViewStatus.success
              ? '${state.room!.driver.name}님의 카풀 정보'
              : '카풀 정보',
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        leading: const BackButton(),
      ),
      body: state.status == CardViewStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : state.status == CardViewStatus.error
          ? Center(child: Text(state.message ?? '에러가 발생했습니다.'))
          : _buildDetailUI(state, viewModel, userId),
    );
  }

  Widget _buildDetailUI(CardViewState state, CarpoolDetailPageViewModel viewModel, int userId) {

    final room = state.room!;
    final mapLat = widget.tabIndex == 0 ? room.originLat : room.destLat;
    final mapLng = widget.tabIndex == 0 ? room.originLng : room.destLng;
    final targetAddress = widget.tabIndex == 0 ? '출발: ${room.origin}' : '도착: ${room.destination}';
    final driver = room.driver;
    final current = room.seatsTotal - room.seatsLeft;
    final timeText = DateFormat('M/d(E) a h:mm', 'ko').format(room.departureTime);

    final isOwner = userId == room.driverId;
    final isFull = current >= room.seatsTotal;
    final isDeparted = DateTime.now().isAfter(room.departureTime);

    final isAppliedByData = state.members.any((m) => m.userId == userId);
    final applied = isAppliedByData || _isAppliedLocal;
    final canJoin = !isOwner && !applied && !isFull;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 30),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(driver.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (isFull) CloseBadge(),
                      ],
                    ),
                    Text(room.carInfo ?? '', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[200],
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

            const SizedBox(height: 24),

            _buildInfoRow(
              Image.asset('assets/images/time_icon.png', width: 24, height: 24),
              '시간: $timeText',
            ),
            const Divider(),
            _buildInfoRow(
              Image.asset('assets/images/departure_icon.png', width: 24, height: 24),
              targetAddress,
            ),
            const Divider(),
            _buildInfoRow(
              Image.asset('assets/images/user_icon.png', width: 24, height: 24),
              '모집인원: $current/${room.seatsTotal}',
            ),
            const Divider(),
            _buildInfoRow(
              Image.asset('assets/images/request_icon.png', width: 24, height: 24),
              '메모: ${room.note ?? ''}',
            ),


            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ButtonView(
                    isApplied: applied,
                    onPressed: canJoin && !isDeparted
                        ? () {
                            setState(() {
                              _isAppliedLocal = true;
                              viewModel.joinCarpool(userId, room.id);
                            });
                          }
                        : null,
                  ),
                ),
                if (applied) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(150, 48),
                        backgroundColor: const Color(0xFFB36BFF),
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
                              roomId: room.id,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(Widget icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            child: icon,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}