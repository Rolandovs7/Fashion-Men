import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/usuarios_service.dart';
import '../services/sucursales_service.dart';
import '../services/catalogo_service.dart';
import '../services/pedidos_service.dart';
import '../services/tipos_pago_service.dart';
import '../shared/admin_shell.dart';

class _ItemVentaPOS {
  final Producto producto;
  final Variante variante;
  int cantidad;

  _ItemVentaPOS({required this.producto, required this.variante, required this.cantidad});
}

// ============================================================
// CU18 - Administrar Venta de Producto (Punto de Venta)
// RF17 - Registrar ventas presenciales (cajero)
// RF18 - Permitir pagos en punto de caja
// Usa CU19 (Tipos de Pago) para el método de pago dinámico.
// Mismo endpoint que Angular: POST /api/pedidos/venta-presencial
// ============================================================
class PuntoVentaPage extends StatefulWidget {
  const PuntoVentaPage({super.key});

  @override
  State<PuntoVentaPage> createState() => _PuntoVentaPageState();
}

class _PuntoVentaPageState extends State<PuntoVentaPage> {
  final usuariosService = UsuariosService();
  final sucursalesService = SucursalesService();
  final catalogoService = CatalogoService();
  final pedidosService = PedidosService();
  final tiposPagoService = TiposPagoService();

  List<Usuario> clientes = [];
  List<Sucursal> sucursales = [];
  List<Producto> productos = [];
  List<Variante> variantesDisponibles = [];

  int? clienteId;
  int? sucursalId;
  String metodoPago = 'efectivo';
  List<TipoPago> tiposPago = [];

  int? productoSeleccionadoId;
  int? varianteSeleccionadaId;
  int cantidadSeleccionada = 1;

  final List<_ItemVentaPOS> itemsVenta = [];

  bool cargando = true;
  bool procesando = false;
  String error = '';
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    try {
      final resultados = await Future.wait([
        usuariosService.listar(),
        sucursalesService.listar(),
        catalogoService.listarProductos(),
      ]);

      // CU19 / RF18-RF19 - catálogo dinámico de métodos de pago habilitados
      try {
        final tipos = await tiposPagoService.listar();
        if (mounted) {
          setState(() {
            tiposPago = tipos;
            if (tipos.isNotEmpty) metodoPago = tipos.first.nombre;
          });
        }
      } catch (_) {
        // Si falla, se deja la lista vacía; el selector simplemente no tendrá opciones.
      }

      setState(() {
        clientes = (resultados[0] as List<Usuario>).where((u) => u.rol == 'cliente' && u.activo).toList();
        sucursales = resultados[1] as List<Sucursal>;
        productos = (resultados[2] as List<Producto>).where((p) => p.activo).toList();
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudo cargar la información del punto de venta.';
        cargando = false;
      });
    }
  }

  Future<void> _cargarVariantes(int productoId) async {
    final vars = await catalogoService.listarVariantesPorProducto(productoId);
    setState(() {
      variantesDisponibles = vars.where((v) => v.stockDisponible > 0).toList();
      varianteSeleccionadaId = null;
    });
  }

  void _agregarItem() {
    final producto = productos.where((p) => p.id == productoSeleccionadoId);
    final variante = variantesDisponibles.where((v) => v.id == varianteSeleccionadaId);

    if (producto.isEmpty || variante.isEmpty) {
      setState(() => error = 'Selecciona un producto y una variante válidos.');
      return;
    }

    if (cantidadSeleccionada < 1 || cantidadSeleccionada > variante.first.stockDisponible) {
      setState(() => error = 'Cantidad inválida. Disponible: ${variante.first.stockDisponible}.');
      return;
    }

    setState(() {
      final existente = itemsVenta.where((i) => i.variante.id == variante.first.id);
      if (existente.isNotEmpty) {
        existente.first.cantidad += cantidadSeleccionada;
      } else {
        itemsVenta.add(_ItemVentaPOS(
          producto: producto.first,
          variante: variante.first,
          cantidad: cantidadSeleccionada,
        ));
      }
      error = '';
      cantidadSeleccionada = 1;
    });
  }

  double get total => itemsVenta.fold(0, (acc, i) => acc + i.producto.precio * i.cantidad);

  Future<void> _registrarVenta() async {
    if (clienteId == null) {
      setState(() => error = 'Selecciona el cliente que realiza la compra.');
      return;
    }
    if (sucursalId == null) {
      setState(() => error = 'Selecciona la sucursal donde se realiza la venta.');
      return;
    }
    if (itemsVenta.isEmpty) {
      setState(() => error = 'Agrega al menos una prenda a la venta.');
      return;
    }

    setState(() {
      procesando = true;
      error = '';
    });

    try {
      final pedido = await pedidosService.crearVentaPresencial(
        usuarioId: clienteId!,
        sucursalId: sucursalId!,
        metodoPago: metodoPago,
        items: itemsVenta.map((i) => {'variante_id': i.variante.id, 'cantidad': i.cantidad}).toList(),
      );

      setState(() {
        procesando = false;
        mensaje = 'Venta #${pedido.id} registrada y pagada por Bs ${pedido.total.toStringAsFixed(2)}.';
        itemsVenta.clear();
        clienteId = null;
      });
    } catch (e) {
      setState(() {
        procesando = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      titulo: 'Punto de Venta',
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (mensaje.isNotEmpty) _banner(mensaje, Colors.green),
                if (error.isNotEmpty) _banner(error, Colors.red),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Datos de la venta', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          initialValue: clienteId,
                          decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder()),
                          items: clientes
                              .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.nombre} ${c.apellido}')))
                              .toList(),
                          onChanged: (v) => setState(() => clienteId = v),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: sucursalId,
                          decoration: const InputDecoration(labelText: 'Sucursal', border: OutlineInputBorder()),
                          items: sucursales
                              .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.nombre} — ${s.ciudad}')))
                              .toList(),
                          onChanged: (v) => setState(() => sucursalId = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Agregar prenda', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          initialValue: productoSeleccionadoId,
                          decoration: const InputDecoration(labelText: 'Producto', border: OutlineInputBorder()),
                          items: productos
                              .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.nombre} — Bs ${p.precio.toStringAsFixed(2)}')))
                              .toList(),
                          onChanged: (v) {
                            setState(() => productoSeleccionadoId = v);
                            if (v != null) _cargarVariantes(v);
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: varianteSeleccionadaId,
                          decoration: const InputDecoration(labelText: 'Talla / Color', border: OutlineInputBorder()),
                          items: variantesDisponibles
                              .map((v) => DropdownMenuItem(
                                    value: v.id,
                                    child: Text('${v.tallaNombre} · ${v.colorNombre} (${v.stockDisponible})'),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => varianteSeleccionadaId = v),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Cantidad:'),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: cantidadSeleccionada > 1
                                  ? () => setState(() => cantidadSeleccionada--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$cantidadSeleccionada'),
                            IconButton(
                              onPressed: () => setState(() => cantidadSeleccionada++),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FilledButton.tonal(
                          onPressed: _agregarItem,
                          child: const Text('+ Agregar a la venta'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...itemsVenta.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${item.variante.tallaNombre} · ${item.variante.colorNombre} × ${item.cantidad}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Bs ${(item.producto.precio * item.cantidad).toStringAsFixed(2)}'),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => itemsVenta.remove(item)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (itemsVenta.isNotEmpty) ...[
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Bs ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: metodoPago,
                    decoration: const InputDecoration(labelText: 'Método de pago', border: OutlineInputBorder()),
                    items: tiposPago.isNotEmpty
                        ? tiposPago.map((t) => DropdownMenuItem(value: t.nombre, child: Text(t.nombre))).toList()
                        : [DropdownMenuItem(value: metodoPago, child: Text(metodoPago))],
                    onChanged: (v) => setState(() => metodoPago = v ?? metodoPago),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: procesando ? null : _registrarVenta,
                      child: Text(procesando ? 'Registrando...' : 'Cobrar y registrar venta'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _banner(String texto, Color color) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );
}
