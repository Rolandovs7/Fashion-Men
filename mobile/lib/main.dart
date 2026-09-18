import 'package:flutter/material.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const MenStyleApp());
}

class MenStyleApp extends StatelessWidget {
  const MenStyleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MenStyle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}