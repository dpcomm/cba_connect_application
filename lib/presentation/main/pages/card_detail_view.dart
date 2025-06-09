import 'package:flutter/material.dart';
import 'package:cba_connect_application/presentation/widgets/close_badge.dart';

class CardDetailView extends StatelessWidget {
  final String region;
  final int totalPeople;
  final int currentPeople;
  final String car;
  final String carColor;
  final String carNumber;
  final String name;
  final String time;
  final String location;

  const CardDetailView({
    super.key,
    required this.region,
    required this.totalPeople,
    required this.currentPeople,
    required this.car,
    required this.carColor,
    required this.carNumber,
    required this.name,
    required this.time,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = currentPeople >= totalPeople;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1행: 지역 / 인원 / 차량 정보
            Row(
              children: [
                const Text('📍', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  region,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Text('👥 $currentPeople/$totalPeople', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text('🚘 $car($carColor)', style: TextStyle(fontSize: 14)),
                if (isFull) ...[
                  const SizedBox(width: 6),
                  CloseBadge(),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // 2행: 이름 / 시간 / 위치
            Row(
              children: [
                const CircleAvatar(radius: 10, backgroundColor: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    location,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}