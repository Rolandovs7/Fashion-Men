import 'package:flutter/material.dart';

import 'admin_catalogo_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_empresas_page.dart';
import 'admin_inventario_page.dart';
import 'admin_operaciones_page.dart';
import 'admin_suscripcion_page.dart';
import 'home_screen.dart';
import 'perfil_page.dart';

/// Shell de navegación para Administrador / SuperAdmin.
/// Muestra gestión (dashboard, catálogo, inventario, operaciones) y,
/// solo para superadmin, la pestaña de Empresas (tenants).
class AdminMainShell extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final int indiceInicial;

  const AdminMainShell({super.key, required this.usuario, this.indiceInicial = 0});

  @override
  State<AdminMainShell> createState() => _AdminMainShellState();
}

class _AdminMainShellState extends State<AdminMainShell> {
  late int _indice;

  bool get _esSuperAdmin => widget.usuario['rol'] == 'superadmin';

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial;
  }

  @override
  Widget build(BuildContext context) {
    final paginas = <Widget>[
      const HomeScreen(),
      const AdminDashboardPage(embedded: true),
      const AdminCatalogoPage(embedded: true),
      const AdminInventarioPage(embedded: true),
      const AdminOperacionesPage(embedded: true),
      if (_esSuperAdmin) const AdminEmpresasPage(embedded: true),
      const AdminSuscripcionPage(embedded: true),
      PerfilPage(usuario: widget.usuario),
    ];

    final destinos = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.checkroom_outlined),
        selectedIcon: Icon(Icons.checkroom),
        label: 'Catálogo',
      ),
      const NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Inventario',
      ),
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Operaciones',
      ),
      if (_esSuperAdmin)
        const NavigationDestination(
          icon: Icon(Icons.apartment_outlined),
          selectedIcon: Icon(Icons.apartment),
          label: 'Empresas',
        ),
      const NavigationDestination(
        icon: Icon(Icons.workspace_premium_outlined),
        selectedIcon: Icon(Icons.workspace_premium),
        label: 'Suscripción',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

    final maxIndex = paginas.length - 1;
    final idx = _indice.clamp(0, maxIndex);

    return Scaffold(
      body: IndexedStack(index: idx, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => _indice = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: destinos,
      ),
    );
  }
}
