import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../shared/menu_drawer.dart';
import '../screens/admin_catalogo_page.dart';
import '../screens/admin_inventario_page.dart';
import '../screens/punto_venta_page.dart';
import '../screens/admin_operaciones_page.dart';
import '../screens/usuarios_page.dart';
import '../screens/permisos_page.dart';
import '../screens/roles_page.dart';
import '../screens/tipos_pago_page.dart';
import '../screens/main_shell.dart';

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
/// `embedded: true` se usa cuando la pantalla vive dentro de un shell
/// con barra de navegación inferior (sin drawer/appbar duplicados).
/// ============================================================
class AdminScaffold extends StatelessWidget {
  final String titulo;
  final Widget body;
  final List<Widget>? acciones;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final bool embedded;

  const AdminScaffold({
    super.key,
    required this.titulo,
    required this.body,
    this.acciones,
    this.floatingActionButton,
    this.bottom,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return Scaffold(
        appBar: bottom == null
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                toolbarHeight: 0,
                elevation: 0,
                bottom: bottom,
              ),
        floatingActionButton: floatingActionButton,
        body: body,
      );
    }
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
  final List<_EnlaceAdmin> enlaces;

  const _GrupoAdmin(this.titulo, this.enlaces);
}

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  // Estructura solicitada:
  // 📦 CATÁLOGO      → Catálogo, Inventario
  // 💰 VENTAS        → Punto de Venta, Operaciones
  // ⚙️ CONFIGURACIÓN → Usuarios, Permisos, Roles, Tipos de Pago
  static final List<_GrupoAdmin> _grupos = [
    _GrupoAdmin('CATÁLOGO', [
      _EnlaceAdmin('Catálogo', Icons.checkroom_outlined, (_) => const AdminCatalogoPage()),
      _EnlaceAdmin('Inventario', Icons.warehouse_outlined, (_) => const AdminInventarioPage()),
    ]),
    _GrupoAdmin('VENTAS', [
      _EnlaceAdmin('Punto de Venta', Icons.point_of_sale_outlined, (_) => const PuntoVentaPage()),
      _EnlaceAdmin('Pedidos y Reservas', Icons.receipt_long_outlined, (_) => const AdminOperacionesPage()),
    ]),
    _GrupoAdmin('CONFIGURACIÓN', [
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
    Navigator.of(context).pop(); // cierra drawer
    final usuario = AuthService.instance.usuarioActual ?? <String, dynamic>{};
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainShell(usuario: usuario, indiceInicial: 1), // Catálogo
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.instance.usuarioActual;
    final nombre = usuario == null
        ? ''
        : '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'.trim();
    final rol = usuario == null ? '' : (usuario['rol'] ?? '').toString();

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            DrawerEncabezado(nombre: nombre, rolEtiqueta: rolEtiquetaDe(rol)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final grupo in _grupos) ...[
                    DrawerSeccion(grupo.titulo),
                    for (final enlace in grupo.enlaces)
                      ListTile(
                        leading: Icon(enlace.icono),
                        title: Text(enlace.etiqueta, style: const TextStyle(fontWeight: FontWeight.w600)),
                        dense: true,
                        onTap: () => _navegar(context, enlace.builder),
                      ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Ir a la tienda', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => _irATienda(context),
            ),
            const DrawerCerrarSesion(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
