import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../shared/menu_drawer.dart';
import 'admin_main_shell.dart';
import 'carrito_page.dart';
import 'catalogo_page.dart';
import 'home_screen.dart';
import 'mis_pedidos_page.dart';
import 'mis_reservas_page.dart';
import 'perfil_page.dart';

class _EntradaMenu {
  final String titulo;
  final IconData icono;
  final Widget pagina;
  const _EntradaMenu(this.titulo, this.icono, this.pagina);
}

class _GrupoMenu {
  final String titulo;
  final List<_EntradaMenu> entradas;
  const _GrupoMenu(this.titulo, this.entradas);
}

/// Shell cliente con Drawer (menú hamburguesa).
/// [Rediseño 2.2/2.3] Navegación por Drawer (sin BottomNavigationBar,
/// por eso nunca supera los 5 ítems de una barra inferior).
/// Menú agrupado con separadores: Tienda / Mis compras / Cuenta.
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

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial;
  }

  List<_GrupoMenu> _grupos() {
    return [
      _GrupoMenu('TIENDA', [
        const _EntradaMenu('Inicio', Icons.home_outlined, HomeScreen()),
        const _EntradaMenu('Catálogo', Icons.checkroom_outlined, CatalogoPage(embedded: true)),
        const _EntradaMenu('Carrito', Icons.local_mall_outlined, CarritoPage(embedded: true)),
      ]),
      _GrupoMenu('MIS COMPRAS', [
        const _EntradaMenu('Pedidos', Icons.receipt_long_outlined, MisPedidosPage(embedded: true)),
        const _EntradaMenu('Reservas', Icons.calendar_month_outlined, MisReservasPage(embedded: true)),
      ]),
      _GrupoMenu('CUENTA', [
        _EntradaMenu('Perfil', Icons.person_outline, PerfilPage(usuario: widget.usuario, embedded: true)),
      ]),
    ];
  }

  void _volverPanelAdmin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AdminMainShell(usuario: widget.usuario)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _grupos();
    final plano = grupos.expand((g) => g.entradas).toList();
    final idx = _indice.clamp(0, plano.length - 1);
    final titulo = plano[idx].titulo;
    final nombre = '${widget.usuario['nombre'] ?? ''} ${widget.usuario['apellido'] ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerEncabezado(nombre: nombre, rolEtiqueta: rolEtiquetaDe(_rol)),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final grupo in grupos) ...[
                      DrawerSeccion(grupo.titulo),
                      for (final entrada in grupo.entradas)
                        ListTile(
                          leading: Icon(entrada.icono),
                          title: Text(entrada.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                          selected: plano.indexOf(entrada) == idx,
                          selectedTileColor: AppTheme.amarilloMarca.withValues(alpha: 0.14),
                          onTap: () {
                            Navigator.of(context).pop();
                            setState(() => _indice = plano.indexOf(entrada));
                          },
                        ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                    if (_tieneAccesoAdmin) ...[
                      DrawerSeccion('ACCESO'),
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings_outlined),
                        title: const Text('Panel de Administración', style: TextStyle(fontWeight: FontWeight.w600)),
                        onTap: _volverPanelAdmin,
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  ],
                ),
              ),
              const DrawerCerrarSesion(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: idx,
        children: plano.map((e) => e.pagina).toList(),
      ),
    );
  }
}
