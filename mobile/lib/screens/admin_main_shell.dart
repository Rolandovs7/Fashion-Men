import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'admin_catalogo_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_empresas_page.dart';
import 'admin_inventario_page.dart';
import 'admin_operaciones_page.dart';
import 'admin_suscripcion_page.dart';
import 'login_page.dart';
import 'main_shell.dart';

class _EntradaMenu {
  final String titulo;
  final IconData icono;
  final Widget pagina;
  const _EntradaMenu(this.titulo, this.icono, this.pagina);
}

/// Shell administrativo con Drawer (menú hamburguesa) y opciones filtradas por rol.
/// - SuperAdmin: solo Dashboard, Empresas, Mi Suscripción.
/// - Administrador: Dashboard, Catálogo, Inventario, Operaciones, Mi Suscripción + Ir a la Tienda.
class AdminMainShell extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final int indiceInicial;

  const AdminMainShell({super.key, required this.usuario, this.indiceInicial = 0});

  @override
  State<AdminMainShell> createState() => _AdminMainShellState();
}

class _AdminMainShellState extends State<AdminMainShell> {
  late int _indice;

  String get _rol => (widget.usuario['rol'] ?? '').toString();
  bool get _esSuperAdmin => _rol == 'superadmin';
  String get _rolEtiqueta => _esSuperAdmin ? 'SuperAdmin' : 'Administrador';

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial;
  }

  List<_EntradaMenu> _entradas() {
    if (_esSuperAdmin) {
      return const [
        _EntradaMenu('Dashboard', Icons.dashboard_outlined, AdminDashboardPage(embedded: true)),
        _EntradaMenu('Empresas', Icons.apartment_outlined, AdminEmpresasPage(embedded: true)),
        _EntradaMenu('Mi Suscripción', Icons.workspace_premium_outlined, AdminSuscripcionPage(embedded: true)),
      ];
    }
    return const [
      _EntradaMenu('Dashboard', Icons.dashboard_outlined, AdminDashboardPage(embedded: true)),
      _EntradaMenu('Catálogo', Icons.checkroom_outlined, AdminCatalogoPage(embedded: true)),
      _EntradaMenu('Inventario', Icons.inventory_2_outlined, AdminInventarioPage(embedded: true)),
      _EntradaMenu('Operaciones', Icons.receipt_long_outlined, AdminOperacionesPage(embedded: true)),
      _EntradaMenu('Mi Suscripción', Icons.workspace_premium_outlined, AdminSuscripcionPage(embedded: true)),
    ];
  }

  Future<void> _cerrarSesion() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _irATienda() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainShell(usuario: widget.usuario, indiceInicial: 1),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entradas = _entradas();
    final idx = _indice.clamp(0, entradas.length - 1);
    final titulo = entradas[idx].titulo;
    final nombre = '${widget.usuario['nombre'] ?? ''} ${widget.usuario['apellido'] ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.black),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('MENSTYLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
                    const SizedBox(height: 6),
                    Text(nombre.isEmpty ? 'Usuario' : nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_rolEtiqueta, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < entradas.length; i++)
                      ListTile(
                        leading: Icon(entradas[i].icono),
                        title: Text(entradas[i].titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                        selected: i == idx,
                        onTap: () {
                          Navigator.of(context).pop();
                          setState(() => _indice = i);
                        },
                      ),
                  ],
                ),
              ),
              if (!_esSuperAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Ir a la Tienda', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: _irATienda,
                ),
              ],
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                onTap: _cerrarSesion,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: idx,
        children: entradas.map((e) => e.pagina).toList(),
      ),
    );
  }
}
