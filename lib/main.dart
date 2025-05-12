import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentation/login/login_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      initialRoute: '/',
      routes: {
        '/': (_) => LoginView(),
        '/home': (_) => Scaffold(
          appBar: AppBar(title: Text('Home')),
          body: Center(child: Text('환영합니다!')),
        ),
      },
    );
  }
}

void main() {
  runApp(ProviderScope(child: MyApp()));
}