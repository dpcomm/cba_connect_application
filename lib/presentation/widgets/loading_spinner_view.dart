// loading_spinner_view.dart
import 'package:flutter/material.dart';

class LoadingSpinnerView extends StatelessWidget {
  final bool isLoading;

  const LoadingSpinnerView({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFF7F19FB),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}



// 로딩 스피너 사용 방법
// 1. 사용하려는 페이지안에 bool 변수 선언
// ->  bool _isLoading = false;

//2. 화면 전체를 감싸는 Stack 안에 LoadingSpinnerView 넣고, isLoading 값에 따라 켜고 끄기
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     body: Stack(
//       children: [
//       /* 기존 화면 UI 부분 */,
//       LoadingSpinnerView(isLoading: _isLoading),    // 추가
//       ],
//     ),
//     floatingActionButton: FloatingActionButton(
//       onPressed: () {
//         setState(() => _isLoading = true);         // 켜기
//         Future.delayed(const Duration(seconds: 2), () {
//           setState(() => _isLoading = false);      // 끄기
//         });
//       },
//       child: Icon(Icons.refresh),
//     ),
//   );
// }
