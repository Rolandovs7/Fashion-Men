import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'admin_main_shell.dart';
import 'carrito_page.dart';
import 'catalogo_page.dart';
import 'home_screen.dart';
import 'login_page.dart';
import 'mis_pedidos_page.dart';
import 'mis_reservas_page.dart';
import 'perfil_page.dart';

class _EntradaMenu {
  final String titulo;
  final IconData icono;
  final Widget pagina;
  const _EntradaMenu(this.titulo, this.icono, this.pagina);
}

/// Shell cliente con Drawer (menú hamburguesa).
/// Menú: Inicio, Catálogo, Carrito, Pedidos, Reservas, Perfil.
/// Si el usuario es Admin/SuperAdmin (vista tienda), muestra "Panel de Administración".
class MainShell extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final int indiceInicial;

  const MainShell({super.key, required this.usuario, this.indiceInicial = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _indice;

  String get _rol => (widget.usuario['rol'] ?? 'cliente').toString();
  bool get _tieneAccesoAdmin => _rol == 'administrador' || _rol == 'superadmin';
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

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial;
  }

  List<_EntradaMenu> _entradas() {
    return [
      const _EntradaMenu('Inicio', Icons.home_outlined, HomeScreen()),
      const _EntradaMenu('Catálogo', Icons.checkroom_outlined, CatalogoPage(embedded: true)),
      const _EntradaMenu('Carrito', Icons.local_mall_outlined, CarritoPage(embedded: true)),
      const _EntradaMenu('Pedidos', Icons.receipt_long_outlined, MisPedidosPage(embedded: true)),
      const _EntradaMenu('Reservas', Icons.calendar_month_outlined, MisReservasPage(embedded: true)),
      _EntradaMenu('Perfil', Icons.person_outline, PerfilPage(usuario: widget.usuario, embedded: true)),
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

  void _volverPanelAdmin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AdminMainShell(usuario: widget.usuario)),
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
              if (_tieneAccesoAdmin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Panel de Administración', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: _volverPanelAdmin,
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
