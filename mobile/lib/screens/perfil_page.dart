import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_page.dart';
import 'main_shell.dart';
import '../core/theme.dart';

class PerfilPage extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const PerfilPage({super.key, required this.usuario});

  String get _rol => (usuario['rol'] ?? 'cliente').toString();

  String get _rolEtiqueta {
    switch (_rol) {
      case 'superadmin':
        return 'SuperAdmin';
      case 'administrador':
        return 'Administrador';
      default:
        return 'Cliente';
    }
  }

  bool get _tieneAccesoAdmin => _rol == 'administrador' || _rol == 'superadmin';

  Future<void> _cerrarSesion(BuildContext context) async {
    await AuthService.instance.logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoPerfil,
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 42,
              backgroundColor: Colors.black,
              child: Icon(Icons.person, size: 46, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'.trim(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _rolEtiqueta,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Correo'),
                    subtitle: Text('${usuario['email'] ?? ''}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Rol'),
                    subtitle: Text(_rol),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: AppTheme.modoNotifier,
                builder: (context, modo, _) {
                  final esOscuro = modo == ThemeMode.dark;
                  return SwitchListTile(
                    secondary: Icon(
                      esOscuro
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                    title: const Text('Modo oscuro'),
                    subtitle: Text(esOscuro ? 'Activado' : 'Desactivado'),
                    value: esOscuro,
                    onChanged: (activar) {
                      AppTheme.modoNotifier.value = activar
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    },
                  );
                },
              ),
            ),
            if (_tieneAccesoAdmin) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => MainShell(
                          usuario: usuario,
                          indiceInicial: 1, // Catálogo (tienda)
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Ir a la tienda'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Ver la app como cliente (catálogo y tienda)',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _cerrarSesion(context),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
