import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const MenStyleApp());
}

class MenStyleApp extends StatelessWidget {
  const MenStyleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.modoNotifier,
      builder: (context, modo, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MenStyle',
          themeMode: modo,
          theme: AppTheme.temaClaro,
          darkTheme: AppTheme.temaOscuro,
          home: const LoginPage(),
        );
      },
    );
  }
}
