import 'package:flutter/material.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: const Center(
        child: Text(
          '검색',
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
    );
  }
}
