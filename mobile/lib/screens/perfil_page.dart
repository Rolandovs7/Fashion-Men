import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'admin_catalogo_page.dart';

// ============================================================
// CU01/CU02 - Autenticación (perfil y cierre de sesión)
// RF: pendiente de confirmar en documentación
// El acceso al panel de administración ahora se centraliza en el
// AdminDrawer (ver shared/admin_shell.dart) — esta pantalla solo
// ofrece un único punto de entrada, para no duplicar la navegación
// administrativa que antes vivía aquí como una lista de botones.
// ============================================================
class PerfilPage extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const PerfilPage({super.key, required this.usuario});

  bool get _esAdministrador => usuario['rol'] == 'administrador';

  Future<void> _cerrarSesion(BuildContext context) async {
    AuthService().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _abrirPanelAdmin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminCatalogoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              '${usuario['nombre']} ${usuario['apellido']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _esAdministrador ? 'Administrador' : 'Cliente',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Correo'),
                    subtitle: Text('${usuario['email']}'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Rol'),
                    subtitle: Text('${usuario['rol']}'),
                  ),
                ],
              ),
            ),
            if (_esAdministrador) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _abrirPanelAdmin(context),
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  label: const Text('Panel de Administración'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Catálogo, Inventario, Ventas, Usuarios, Permisos, Roles y Tipos de Pago',
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
