import 'package:flutter/material.dart';

import 'catalogo_page.dart';
import 'carrito_page.dart';
import 'home_screen.dart';
import 'mis_pedidos_page.dart';
import 'mis_reservas_page.dart';
import 'notificaciones_page.dart';
import 'perfil_page.dart';
import 'punto_venta_screen.dart';

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
      const HomeScreen(),
      const CatalogoPage(),
      const CarritoPage(),
      const MisPedidosPage(),
      const PuntoVentaScreen(),
      const MisReservasPage(),
      const NotificacionesPage(),
      PerfilPage(usuario: widget.usuario),
    ];

    return Scaffold(
      body: IndexedStack(index: indiceActual, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceActual,
        onDestinationSelected: (i) => setState(() => indiceActual = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
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
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'POS',
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
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
