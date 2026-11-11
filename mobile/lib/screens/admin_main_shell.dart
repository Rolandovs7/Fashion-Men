import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../shared/menu_drawer.dart';
import 'admin_catalogo_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_empresas_page.dart';
import 'admin_inventario_page.dart';
import 'admin_operaciones_page.dart';
import 'admin_suscripcion_page.dart';
import 'asistente_ia_page.dart';
import 'main_shell.dart';

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

/// Shell administrativo con Drawer (menú hamburguesa) y opciones filtradas por rol.
/// [Rediseño 2.2] Menú agrupado con separadores y "Cerrar sesión" en rojo al final.
/// [Rediseño 2.9] El menú de operaciones se llama "Pedidos y Reservas".
/// [CU23] "Asistente IA" disponible para admin y superadmin.
/// - SuperAdmin: Dashboard, Asistente IA, Empresas, Mi Suscripción.
/// - Administrador: Dashboard, Catálogo, Inventario, Pedidos y Reservas,
///   Asistente IA, Mi Suscripción + Ir a la Tienda.
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

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial;
  }

  List<_GrupoMenu> _grupos() {
    if (_esSuperAdmin) {
      return const [
        _GrupoMenu('GENERAL', [
          _EntradaMenu('Dashboard', Icons.dashboard_outlined, AdminDashboardPage(embedded: true)),
          _EntradaMenu('Asistente IA', Icons.smart_toy_outlined, AsistenteIaPage(embedded: true)),
        ]),
        _GrupoMenu('SAAS', [
          _EntradaMenu('Empresas', Icons.apartment_outlined, AdminEmpresasPage(embedded: true)),
          _EntradaMenu('Mi Suscripción', Icons.workspace_premium_outlined, AdminSuscripcionPage(embedded: true)),
        ]),
      ];
    }
    return const [
      _GrupoMenu('GENERAL', [
        _EntradaMenu('Dashboard', Icons.dashboard_outlined, AdminDashboardPage(embedded: true)),
      ]),
      _GrupoMenu('GESTIÓN', [
        _EntradaMenu('Catálogo', Icons.checkroom_outlined, AdminCatalogoPage(embedded: true)),
        _EntradaMenu('Inventario', Icons.inventory_2_outlined, AdminInventarioPage(embedded: true)),
        _EntradaMenu('Pedidos y Reservas', Icons.receipt_long_outlined, AdminOperacionesPage(embedded: true)),
        _EntradaMenu('Asistente IA', Icons.smart_toy_outlined, AsistenteIaPage(embedded: true)),
      ]),
      _GrupoMenu('SAAS', [
        _EntradaMenu('Mi Suscripción', Icons.workspace_premium_outlined, AdminSuscripcionPage(embedded: true)),
      ]),
    ];
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
              DrawerEncabezado(
                nombre: nombre,
                rolEtiqueta: _esSuperAdmin ? 'SuperAdmin' : 'Administrador',
              ),
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
                    if (!_esSuperAdmin) ...[
                      DrawerSeccion('TIENDA'),
                      ListTile(
                        leading: const Icon(Icons.storefront_outlined),
                        title: const Text('Ir a la Tienda', style: TextStyle(fontWeight: FontWeight.w600)),
                        onTap: _irATienda,
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
