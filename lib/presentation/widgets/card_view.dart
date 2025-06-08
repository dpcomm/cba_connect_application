import 'package:flutter/material.dart';
import 'package:cba_connect_application/presentation/widgets/button_view.dart';
import 'package:cba_connect_application/presentation/widgets/close_badge.dart';


class CardView extends StatefulWidget {
  final String name;
  final String region;
  final String carColor;
  final String time;
  final String location;
  final String phone;
  final int totalPeople;
  final int currentPeople;
  final String car;
  final String carNumber;
  final String message;
  final bool isApplied;

  const CardView({
    Key? key,
    required this.name,
    required this.region,
    required this.carColor,
    required this.time,
    required this.location,
    required this.phone,
    required this.totalPeople,
    required this.currentPeople,
    required this.car,
    required this.carNumber,
    required this.message,
    this.isApplied = false,
  }) : super(key: key);

  @override
  State<CardView> createState() => _CarpoolDetailPageState();
}

class _CarpoolDetailPageState extends State<CardView> {
  late bool _isApplied;

  @override
  void initState() {
    super.initState();
    _isApplied = widget.isApplied;
  }

  @override
  void didUpdateWidget(covariant CardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isApplied != widget.isApplied) {
      setState(() {
        _isApplied = widget.isApplied;
      });
    }
  }

  void _applyCarpool() {
    setState(() {
      _isApplied = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text('${widget.name}님의 카풀 정보',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        leading: const BackButton(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 프로필
                      Row(
                        children: [
                          const CircleAvatar(radius: 30),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${widget.name}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  if (widget.currentPeople >= widget.totalPeople)
                                    CloseBadge(),
                                ],
                              ),
                              Text('${widget.phone} | ${widget.car} | ${widget.carNumber}',
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 지도
                      Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Text("지도 마커 생성 & 카풀 픽업 위치 표시"),
                      ),

                      const SizedBox(height: 24),
                      // _buildInfoRow(Icons.calendar_today, '${widget.time}'),
                      // const SizedBox(height: 8),
                      // const Divider(),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 6),
                            _buildInfoRow(Icons.location_pin, '시간: ${widget.time} \n장소: ${widget.location}'),
                            const SizedBox(height: 6),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.bolt, '요청사항: ${widget.message}'),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 6),
                            _buildInfoRow(
                              Icons.people,
                              '모집인원: ${widget.currentPeople} / ${widget.totalPeople} ',
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 하단 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ButtonView(
                              isApplied: _isApplied,
                              onPressed: (_isApplied || widget.currentPeople >= widget.totalPeople) ? null : _applyCarpool,
                            ),
                          ),
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
                                // 메시지 버튼 로직
                              },
                              child: const Text(
                                '메시지',
                                style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade300,
          child: Icon(
            icon,
            color: Colors.grey.shade700,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}