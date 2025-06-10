import 'package:cba_connect_application/presentation/main/pages/home/registration_view.dart';
import 'package:flutter/material.dart';

class DestinationSelectionView extends StatefulWidget {
  const DestinationSelectionView({super.key});

  @override
  State<DestinationSelectionView> createState() => _DestinationSelectionViewState();
}

class _DestinationSelectionViewState extends State<DestinationSelectionView> {
  String? selectedDestination; // 선택된 버튼의 목적지를 저장

  void _navigateToRegister(BuildContext context, String destination) {
    setState(() {
      selectedDestination = destination;
    });

    // 잠깐 색이 바뀐 후 페이지 이동 (약간의 delay)
    Future.delayed(const Duration(milliseconds: 200), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationView(destination: destination),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {

    Widget buildDestinationCard({
      required String label,
      required IconData icon,
      required String destination,
      required Color iconColor,
    }) {
      final bool isSelected = selectedDestination == destination;

      return GestureDetector(
        onTap: () => _navigateToRegister(context, destination),
        child: Card(
          color: isSelected ? const Color(0xFF7F19FB) : Colors.grey[200],
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: 150,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: isSelected ? Colors.white : iconColor, // 여기!
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: const BackButton(),
        title: const Text(
          '카풀 등록',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          const Divider(
            thickness: 1,
            color: Colors.black12,
            indent: 16,
            endIndent: 16,
          ),
          const SizedBox(height: 10),
          const Center(
              child: Text("목적지 선택", style: TextStyle(fontSize: 20))),
          const SizedBox(height: 10),
          const Divider(
            thickness: 1,
            color: Colors.black12,
            indent: 16,
            endIndent: 16,
          ),
          const SizedBox(height: 20),
          buildDestinationCard(
            label: "수련회장으로",
            icon: Icons.favorite,
            destination: "수련회장",
            iconColor: Colors.pink,
          ),
          buildDestinationCard(
            label: "집으로",
            icon: Icons.home,
            destination: "집",
            iconColor: Colors.orange,
          )

        ],
      ),
    );
  }
}