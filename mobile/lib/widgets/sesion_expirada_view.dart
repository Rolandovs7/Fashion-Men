import 'package:flutter/material.dart';

import '../screens/login_page.dart';
import '../services/auth_service.dart';

class SesionExpiradaView extends StatelessWidget {
  final String mensaje;
  final VoidCallback? onReintentar;

  const SesionExpiradaView({
    super.key,
    this.mensaje = 'Tu sesión expiró o no tienes permisos.',
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 52, color: Colors.grey.shade500),
            const SizedBox(height: 14),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () async {
                await AuthService.instance.limpiarSesion();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Volver a iniciar sesión'),
            ),
            if (onReintentar != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> irALogin(BuildContext context) async {
  await AuthService.instance.limpiarSesion();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}
