import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/carrito_service.dart';
import '../services/catalogo_service.dart';
import '../services/sucursales_service.dart';
import '../services/pedidos_service.dart';
import '../services/reservas_service.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';

class _ItemCarritoVista {
  final DetalleCarrito detalle;
  final Variante? variante;
  final Producto? producto;

  _ItemCarritoVista({required this.detalle, this.variante, this.producto});

  double get subtotal =>
      producto != null ? producto!.precio * detalle.cantidad : 0;
}

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  final carritoService = CarritoService();
  final catalogoService = CatalogoService();
  final sucursalesService = SucursalesService();
  final pedidosService = PedidosService();
  final reservasService = ReservasService();

  List<_ItemCarritoVista> items = [];
  List<Sucursal> sucursales = [];

  bool cargando = true;
  bool procesando = false;
  String error = '';
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  double get total => items.fold(0, (acc, i) => acc + i.subtotal);

  Future<void> _cargar() async {
    if (AuthService.instance.token == null) {
      setState(() {
        cargando = false;
        error = 'Inicia sesión para ver tu carrito.';
      });
      return;
    }

    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final carrito = await carritoService.obtener();

      final itemsResueltos = <_ItemCarritoVista>[];
      for (final detalle in carrito.detalles) {
        try {
          final variante = await catalogoService.obtenerVariante(
            detalle.varianteId,
          );
          final producto = await catalogoService.obtenerProducto(
            variante.productoId,
          );
          itemsResueltos.add(
            _ItemCarritoVista(
              detalle: detalle,
              variante: variante,
              producto: producto,
            ),
          );
        } catch (_) {
          itemsResueltos.add(_ItemCarritoVista(detalle: detalle));
        }
      }

      final sucursalesResultado = await sucursalesService.listar();

      setState(() {
        items = itemsResueltos;
        sucursales = sucursalesResultado;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudo cargar el carrito.';
        cargando = false;
      });
    }
  }

  Future<void> _cambiarCantidad(
    _ItemCarritoVista item,
    int nuevaCantidad,
  ) async {
    if (nuevaCantidad < 1) return;
    try {
      await carritoService.actualizarItem(item.detalle.id, nuevaCantidad);
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _eliminarItem(_ItemCarritoVista item) async {
    try {
      await carritoService.eliminarItem(item.detalle.id);
      setState(() => mensaje = 'Prenda eliminada del carrito.');
      _cargar();
    } catch (_) {
      setState(() => error = 'No se pudo eliminar la prenda.');
    }
  }

  Future<void> _comprarAhora() async {
    final sucursalId = await _elegirSucursal(
      titulo: 'Elige la sucursal para tu compra',
    );
    if (sucursalId == null) return;

    setState(() => procesando = true);
    try {
      final pedido = await pedidosService.crearDesdeCarrito(sucursalId);
      if (!mounted) return;
      setState(() {
        procesando = false;
        mensaje = 'Pedido #${pedido.id} creado. Ve a "Pedidos" para pagarlo.';
      });
      _cargar();
    } catch (e) {
      setState(() {
        procesando = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _reservarParaProbar() async {
    final sucursalId = await _elegirSucursal(
      titulo: 'Elige la sucursal para probarte las prendas',
    );
    if (sucursalId == null) return;

    if (!mounted) return;
    final fecha = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (fecha == null) return;

    if (!mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (hora == null) return;

    final fechaHora = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    final detalles = items
        .where((i) => i.variante != null)
        .map(
          (i) => {
            'variante_id': i.variante!.id,
            'cantidad': i.detalle.cantidad,
          },
        )
        .toList();

    if (detalles.isEmpty) {
      setState(() => error = 'No hay prendas válidas para reservar.');
      return;
    }

    setState(() => procesando = true);
    try {
      final reserva = await reservasService.crear(
        sucursalId: sucursalId,
        fechaReserva: fechaHora,
        detalles: detalles,
      );
      if (!mounted) return;
      setState(() {
        procesando = false;
        mensaje = 'Reserva #${reserva.id} creada correctamente.';
      });
    } catch (e) {
      setState(() {
        procesando = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<int?> _elegirSucursal({required String titulo}) {
    if (sucursales.isEmpty) {
      setState(() => error = 'No hay sucursales disponibles.');
      return Future.value(null);
    }

    return showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...sucursales.map(
              (s) => ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(s.nombre),
                subtitle: Text(s.ciudad),
                onTap: () => Navigator.of(context).pop(s.id),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoCarrito,
      appBar: AppBar(title: const Text('Tu carrito')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (mensaje.isNotEmpty)
                    _Banner(texto: mensaje, color: Colors.green),
                  if (error.isNotEmpty)
                    _Banner(texto: error, color: Colors.red),
                  if (!cargando && items.isEmpty && error.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'Tu carrito está vacío.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ...items.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF262626),
                                    Color(0xFF000000),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.checkroom,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.producto?.nombre ??
                                        'Producto no disponible',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (item.variante != null)
                                    Text(
                                      'Talla ${item.variante!.tallaNombre} · ${item.variante!.colorNombre}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  Text(
                                    'Bs ${item.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: item.detalle.cantidad > 1
                                  ? () => _cambiarCantidad(
                                      item,
                                      item.detalle.cantidad - 1,
                                    )
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${item.detalle.cantidad}'),
                            IconButton(
                              onPressed: () => _cambiarCantidad(
                                item,
                                item.detalle.cantidad + 1,
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              onPressed: () => _eliminarItem(item),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (items.isNotEmpty) ...[
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Bs ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: procesando ? null : _comprarAhora,
                        child: Text(
                          procesando ? 'Procesando...' : 'Comprar ahora',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: procesando ? null : _reservarParaProbar,
                        child: const Text('Reservar para probar en tienda'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String texto;
  final Color color;

  const _Banner({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
