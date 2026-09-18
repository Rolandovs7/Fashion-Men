import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_page.dart';
import '../screens/admin_catalogo_page.dart';
import '../screens/admin_inventario_page.dart';
import '../screens/punto_venta_page.dart';
import '../screens/admin_operaciones_page.dart';
import '../screens/usuarios_page.dart';
import '../screens/permisos_page.dart';
import '../screens/roles_page.dart';
import '../screens/tipos_pago_page.dart';

/// ============================================================
/// AdminShell (Flutter) — equivalente al `AdminShell` de Angular.
/// Centraliza la navegación administrativa: Drawer agrupado por
/// dominio (Catálogo / Ventas / Configuración), AppBar común,
/// acceso rápido a la tienda y cierre de sesión.
///
/// Reutiliza el mismo `AuthService` y las mismas pantallas admin
/// que ya existían — no duplica lógica ni crea servicios nuevos.
///
/// Uso: envolver el contenido de cada pantalla admin con
/// `AdminScaffold(titulo: '...', body: ...)` en vez de que cada
/// pantalla arme su propio Scaffold + Drawer por separado.
/// ============================================================
class AdminScaffold extends StatelessWidget {
  final String titulo;
  final Widget body;
  final List<Widget>? acciones;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;

  const AdminScaffold({
    super.key,
    required this.titulo,
    required this.body,
    this.acciones,
    this.floatingActionButton,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: acciones,
        bottom: bottom,
      ),
      drawer: const AdminDrawer(),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

class _EnlaceAdmin {
  final String etiqueta;
  final IconData icono;
  final WidgetBuilder builder;

  const _EnlaceAdmin(this.etiqueta, this.icono, this.builder);
}

class _GrupoAdmin {
  final String titulo;
  final IconData icono;
  final List<_EnlaceAdmin> enlaces;

  const _GrupoAdmin(this.titulo, this.icono, this.enlaces);
}

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  // Estructura solicitada:
  // 📦 CATÁLOGO      → Catálogo, Inventario
  // 💰 VENTAS        → Punto de Venta, Operaciones
  // ⚙️ CONFIGURACIÓN → Usuarios, Permisos, Roles, Tipos de Pago
  static final List<_GrupoAdmin> _grupos = [
    _GrupoAdmin('CATÁLOGO', Icons.inventory_2_outlined, [
      _EnlaceAdmin('Catálogo', Icons.checkroom_outlined, (_) => const AdminCatalogoPage()),
      _EnlaceAdmin('Inventario', Icons.warehouse_outlined, (_) => const AdminInventarioPage()),
    ]),
    _GrupoAdmin('VENTAS', Icons.attach_money, [
      _EnlaceAdmin('Punto de Venta', Icons.point_of_sale_outlined, (_) => const PuntoVentaPage()),
      _EnlaceAdmin('Operaciones', Icons.receipt_long_outlined, (_) => const AdminOperacionesPage()),
    ]),
    _GrupoAdmin('CONFIGURACIÓN', Icons.settings_outlined, [
      _EnlaceAdmin('Usuarios', Icons.people_outline, (_) => const UsuariosPage()),
      _EnlaceAdmin('Permisos', Icons.lock_outline, (_) => const PermisosPage()),
      _EnlaceAdmin('Roles', Icons.badge_outlined, (_) => const RolesPage()),
      _EnlaceAdmin('Tipos de Pago', Icons.payments_outlined, (_) => const TiposPagoPage()),
    ]),
  ];

  void _navegar(BuildContext context, WidgetBuilder builder) {
    Navigator.of(context).pop(); // cierra el drawer
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: builder),
    );
  }

  void _irATienda(BuildContext context) {
    // La tienda (MainShell) sigue en la pila de navegación por debajo
    // de las pantallas admin (se llega aquí desde Perfil vía push, y
    // entre pantallas admin se usa pushReplacement) — basta con volver
    // a la primera ruta en vez de reconstruir MainShell.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _cerrarSesion(BuildContext context) {
    AuthService.instance.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.instance.usuarioActual;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'MENSTYLE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ADMINISTRACIÓN',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  if (usuario != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final grupo in _grupos) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Row(
                        children: [
                          Icon(grupo.icono, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            grupo.titulo,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final enlace in grupo.enlaces)
                      ListTile(
                        leading: Icon(enlace.icono),
                        title: Text(enlace.etiqueta, style: const TextStyle(fontWeight: FontWeight.w600)),
                        dense: true,
                        onTap: () => _navegar(context, enlace.builder),
                      ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Ir a la tienda', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => _irATienda(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              onTap: () => _cerrarSesion(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
