import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/admin_catalogo_page.dart';
import 'screens/login_page.dart';
import 'screens/main_shell.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
          home: const _AuthGate(),
        );
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    _resolver();
  }

  Future<void> _resolver() async {
    final ok = await AuthService.instance.restaurarSesion();
    if (!mounted) return;
    if (ok && AuthService.instance.token != null) {
      final usuario = AuthService.instance.usuarioActual ?? <String, dynamic>{};
      final Widget destino = AuthService.instance.tieneAccesoAdmin
          ? const AdminCatalogoPage()
          : MainShell(usuario: usuario);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destino),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
