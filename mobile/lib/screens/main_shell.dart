import 'package:flutter/material.dart';

import 'catalogo_page.dart';
import 'carrito_page.dart';
import 'mis_pedidos_page.dart';
import 'mis_reservas_page.dart';
import 'notificaciones_page.dart';
import 'perfil_page.dart';

class MainShell extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const MainShell({super.key, required this.usuario});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int indiceActual = 0;

  @override
  Widget build(BuildContext context) {
    final paginas = [
      const CatalogoPage(),
      const CarritoPage(),
      const MisPedidosPage(),
      const MisReservasPage(),
      const NotificacionesPage(),
      PerfilPage(usuario: widget.usuario),
    ];

    return Scaffold(
      body: IndexedStack(index: indiceActual, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceActual,
        onDestinationSelected: (i) => setState(() => indiceActual = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_mall_outlined),
            selectedIcon: Icon(Icons.local_mall),
            label: 'Carrito',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_edu_outlined),
            selectedIcon: Icon(Icons.history_edu),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Reservas',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Avisos',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
