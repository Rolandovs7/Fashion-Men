import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/sesion.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/carrito_service.dart';
import '../services/catalogo_service.dart';
import '../services/pedidos_service.dart';
import '../services/reservas_service.dart';
import '../services/sucursales_service.dart';
import '../widgets/sesion_expirada_view.dart';

class _ItemCarritoVista {
  final DetalleCarrito detalle;
  final Variante? variante;
  final Producto? producto;

  _ItemCarritoVista({required this.detalle, this.variante, this.producto});

  double get subtotal =>
      producto != null ? producto!.precio * detalle.cantidad : 0;
}

class CarritoPage extends StatefulWidget {
  final bool embedded;
  const CarritoPage({super.key, this.embedded = false});

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
  bool sesionExpirada = false;

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
        sesionExpirada = true;
        error = '';
      });
      return;
    }

    setState(() {
      cargando = true;
      error = '';
      sesionExpirada = false;
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
        } catch (e) {
          if (e is SesionExpiradaException) rethrow;
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
      // ignore: avoid_print
      print('[CarritoPage] Error cargando carrito: $e');
      if (!mounted) return;
      setState(() {
        sesionExpirada = e is SesionExpiradaException;
        error = sesionExpirada ? '' : e.toString().replaceFirst('Exception: ', '');
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
      // [Fix 1.3] Checkout sin redirección automática ante un 401 real:
      // se muestra el mensaje inline con botón, sin cerrar la app. Los
      // 400/402/403/422 conservan el mensaje real del backend.
      final pedido = await ApiClient.sinRedireccionAutomatica(
        () => pedidosService.crearDesdeCarrito(sucursalId),
      );
      if (!mounted) return;
      setState(() {
        procesando = false;
        mensaje = 'Pedido #${pedido.id} creado. Ve a "Pedidos" para pagarlo.';
      });
      _cargar();
    } on SesionExpiradaException {
      if (!mounted) return;
      setState(() {
        procesando = false;
        sesionExpirada = true;
        error = '';
      });
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

  /// [Rediseño] Item del carrito con imagen 56x56, nombre y talla/color.
  Widget _tarjetaItem(_ItemCarritoVista item) {
    final url = AppConfig.urlCompleta(item.producto?.imagenUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: url == null
                        ? _imagenFallback()
                        : Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _imagenFallback(),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.producto?.nombre ?? 'Producto no disponible',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppTheme.negro,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (item.variante != null)
                        Text(
                          'Talla ${item.variante!.tallaNombre} · ${item.variante!.colorNombre}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        'Bs ${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar del carrito',
                  onPressed: () => _eliminarItem(item),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Cantidad',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                _controlCantidad(
                  icono: Icons.remove,
                  onTap: item.detalle.cantidad > 1
                      ? () => _cambiarCantidad(
                          item,
                          item.detalle.cantidad - 1,
                        )
                      : null,
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    '${item.detalle.cantidad}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                _controlCantidad(
                  icono: Icons.add,
                  onTap: () => _cambiarCantidad(
                    item,
                    item.detalle.cantidad + 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagenFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF262626), Color(0xFF000000)],
        ),
      ),
      child: const Icon(Icons.checkroom, color: Colors.white54, size: 24),
    );
  }

  Widget _controlCantidad({
    required IconData icono,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icono, size: 16),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoCarrito,
      appBar: widget.embedded ? null : AppBar(title: const Text('Tu carrito')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : sesionExpirada
              ? const SesionExpiradaView(
                  mensaje: 'Tu sesión expiró. Iniciá sesión de nuevo',
                )
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
                  ...items.map((item) => _tarjetaItem(item)),
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
