import 'package:flutter/material.dart';
import 'catalogo_page.dart';
import 'carrito_page.dart';
import 'mis_pedidos_page.dart';
import 'mis_reservas_page.dart';
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
      PerfilPage(usuario: widget.usuario),
    ];

    return Scaffold(
      body: IndexedStack(
        index: indiceActual,
        children: paginas,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceActual,
        onDestinationSelected: (i) => setState(() => indiceActual = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Carrito',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Reservas',
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
