import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'main_shell.dart';
import 'mis_pedidos_page.dart';
import 'mis_reservas_page.dart';

/// ============================================================
/// [Rediseño 2.11] Perfil por secciones: cabecera con avatar,
/// nombre y rol; sección Cuenta (correo/rol); sección Mis Compras
/// (pedidos y reservas); acceso a la tienda (solo admin) y
/// Cerrar sesión.
/// ============================================================
class PerfilPage extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final bool embedded;

  const PerfilPage({super.key, required this.usuario, this.embedded = false});

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

  void _abrirMisPedidos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MisPedidosPage()),
    );
  }

  void _abrirMisReservas(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MisReservasPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreCompleto = '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'.trim();
    final inicial = nombreCompleto.isNotEmpty ? nombreCompleto[0].toUpperCase() : 'U';

    final body = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ---------------- Cabecera ----------------
        CircleAvatar(
          radius: 44,
          backgroundColor: AppTheme.negro,
          child: Text(
            inicial,
            style: const TextStyle(
              color: AppTheme.amarilloMarca,
              fontWeight: FontWeight.w800,
              fontSize: 30,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          nombreCompleto.isEmpty ? 'Usuario' : nombreCompleto,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.amarilloMarca.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _rolEtiqueta,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.negro,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ---------------- Sección: Cuenta ----------------
        _tituloSeccion('CUENTA'),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Correo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('${usuario['email'] ?? ''}'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Rol', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(_rolEtiqueta),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ---------------- Sección: Mis compras ----------------
        _tituloSeccion('MIS COMPRAS'),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Mis pedidos', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Historial, pagos y estado de envío', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrirMisPedidos(context),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Mis reservas', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Reservas en sucursales y su estado', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrirMisReservas(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ---------------- Sección: Administración ----------------
        if (_tieneAccesoAdmin) ...[
          _tituloSeccion('ADMINISTRACIÓN'),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Ir a la tienda', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Ver la app como cliente (catálogo y tienda)', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
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
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ---------------- Cerrar sesión ----------------
        OutlinedButton.icon(
          onPressed: () => _cerrarSesion(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size.fromHeight(50),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 24),
      ],
    );

    return Scaffold(
      backgroundColor: AppTheme.fondoPerfil,
      appBar: embedded ? null : AppBar(title: const Text('Mi perfil')),
      body: body,
    );
  }

  Widget _tituloSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppTheme.grisTexto,
        ),
      ),
    );
  }
}
