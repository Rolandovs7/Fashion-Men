import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/inventario_service.dart';
import '../services/sucursales_service.dart';
import '../services/catalogo_service.dart';
import '../shared/admin_shell.dart';

// ============================================================
// CU15 - Pantalla de Gestión de Inventario
// RF20 - Actualizar automáticamente el inventario tras una venta
// RF21 - Controlar las existencias por sucursal
// RF22 - Registrar movimientos de inventario
// Equivalente a admin-inventario (Angular). Selecciona sucursal,
// muestra stock por variante (talla/color), permite registrar,
// editar y eliminar. Mismos endpoints /api/inventario que Angular.
// ============================================================
class _FilaInventario {
  final Inventario inventario;
  Variante? variante;
  Producto? producto;
  bool editando = false;
  int? cantidadEdit;
  int? reservadaEdit;

  _FilaInventario(this.inventario);
}

class AdminInventarioPage extends StatefulWidget {
  const AdminInventarioPage({super.key});

  @override
  State<AdminInventarioPage> createState() => _AdminInventarioPageState();
}

class _AdminInventarioPageState extends State<AdminInventarioPage> {
  final inventarioService = InventarioService();
  final sucursalesService = SucursalesService();
  final catalogoService = CatalogoService();

  List<Sucursal> sucursales = [];
  List<Producto> productos = [];
  List<Variante> variantesDelProducto = [];
  List<_FilaInventario> filas = [];

  int? sucursalSeleccionadaId;
  int? productoSeleccionadoId;
  int? varianteSeleccionadaId;
  int cantidadNueva = 0;

  bool cargando = true;
  bool guardando = false;
  String error = '';
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    _cargarInicial();
  }

  Future<void> _cargarInicial() async {
    try {
      final sucursalesResultado = await sucursalesService.listar();
      final productosResultado = await catalogoService.listarProductos();

      setState(() {
        sucursales = sucursalesResultado;
        productos = productosResultado.where((p) => p.activo).toList();
      });

      if (sucursales.isNotEmpty) {
        sucursalSeleccionadaId = sucursales.first.id;
        await _cargarInventario();
      } else {
        setState(() => cargando = false);
      }
    } catch (e) {
      setState(() {
        error = 'No se pudo cargar la información inicial.';
        cargando = false;
      });
    }
  }

  // CU15 / RF21 - Consulta el inventario de la sucursal seleccionada
  Future<void> _cargarInventario() async {
    if (sucursalSeleccionadaId == null) return;

    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final inventarios = await inventarioService.listar(sucursalId: sucursalSeleccionadaId);
      await _resolverFilas(inventarios);
    } catch (e) {
      setState(() {
        error = 'No se pudo cargar el inventario de esta sucursal.';
        cargando = false;
      });
    }
  }

  Future<void> _resolverFilas(List<Inventario> inventarios) async {
    final nuevasFilas = <_FilaInventario>[];

    for (final inv in inventarios) {
      final fila = _FilaInventario(inv);
      try {
        fila.variante = await catalogoService.obtenerVariante(inv.varianteId);
        if (fila.variante != null) {
          fila.producto = await catalogoService.obtenerProducto(fila.variante!.productoId);
        }
      } catch (_) {
        // Si no se puede resolver el nombre, igual se muestra la fila con el ID.
      }
      nuevasFilas.add(fila);
    }

    setState(() {
      filas = nuevasFilas;
      cargando = false;
    });
  }

  Future<void> _cargarVariantesDelProducto(int? productoId) async {
    setState(() {
      productoSeleccionadoId = productoId;
      varianteSeleccionadaId = null;
      variantesDelProducto = [];
    });

    if (productoId == null) return;

    final variantes = await catalogoService.listarVariantesPorProducto(productoId);
    setState(() => variantesDelProducto = variantes);
  }

  // CU15 / RF20 - Registra stock nuevo para una variante en la sucursal actual
  Future<void> _agregarStock() async {
    if (sucursalSeleccionadaId == null || varianteSeleccionadaId == null || cantidadNueva < 0) {
      setState(() => error = 'Selecciona producto, variante y una cantidad válida.');
      return;
    }

    setState(() {
      guardando = true;
      error = '';
    });

    try {
      await inventarioService.crear(
        varianteId: varianteSeleccionadaId!,
        sucursalId: sucursalSeleccionadaId!,
        cantidad: cantidadNueva,
      );
      setState(() {
        guardando = false;
        mensaje = 'Stock registrado correctamente.';
        productoSeleccionadoId = null;
        varianteSeleccionadaId = null;
        cantidadNueva = 0;
      });
      _cargarInventario();
    } catch (e) {
      setState(() {
        guardando = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _editarFila(_FilaInventario fila) {
    setState(() {
      fila.editando = true;
      fila.cantidadEdit = fila.inventario.cantidad;
      fila.reservadaEdit = fila.inventario.cantidadReservada;
    });
  }

  // CU15 / RF22 - Actualiza cantidad/reservado (movimiento de inventario)
  Future<void> _guardarFila(_FilaInventario fila) async {
    if (fila.cantidadEdit == null || fila.reservadaEdit == null || fila.reservadaEdit! > fila.cantidadEdit!) {
      setState(() => error = 'La cantidad reservada no puede ser mayor que la cantidad total.');
      return;
    }

    try {
      await inventarioService.actualizar(
        fila.inventario.id,
        cantidad: fila.cantidadEdit,
        cantidadReservada: fila.reservadaEdit,
      );
      setState(() => mensaje = 'Inventario actualizado correctamente.');
      _cargarInventario();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _eliminarFila(_FilaInventario fila) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este registro de inventario?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, eliminar')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await inventarioService.eliminar(fila.inventario.id);
      setState(() {
        filas.remove(fila);
        mensaje = 'Registro de inventario eliminado.';
      });
    } catch (e) {
      setState(() => error = 'No se pudo eliminar el registro.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      titulo: 'Inventario',
      body: RefreshIndicator(
        onRefresh: _cargarInventario,
        child: ListView(
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
                    const Text('Sucursal', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: sucursalSeleccionadaId,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      items: sucursales
                          .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.nombre} — ${s.ciudad}')))
                          .toList(),
                      onChanged: (v) {
                        setState(() => sucursalSeleccionadaId = v);
                        _cargarInventario();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Registrar stock', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: productoSeleccionadoId,
                      decoration: const InputDecoration(labelText: 'Producto', border: OutlineInputBorder(), isDense: true),
                      items: productos.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre))).toList(),
                      onChanged: _cargarVariantesDelProducto,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: varianteSeleccionadaId,
                      decoration: const InputDecoration(labelText: 'Talla / Color', border: OutlineInputBorder(), isDense: true),
                      items: variantesDelProducto
                          .map((v) => DropdownMenuItem(value: v.id, child: Text('${v.tallaNombre} · ${v.colorNombre}')))
                          .toList(),
                      onChanged: (v) => setState(() => varianteSeleccionadaId = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cantidad inicial', border: OutlineInputBorder(), isDense: true),
                      onChanged: (v) => cantidadNueva = int.tryParse(v) ?? 0,
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: guardando ? null : _agregarStock,
                      child: Text(guardando ? 'Guardando...' : 'Registrar stock'),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Si la variante ya tiene stock en esta sucursal, edítalo directamente en la lista.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (cargando)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filas.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: Text('Sin registros de inventario para esta sucursal.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...filas.map(
                (fila) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fila.producto?.nombre ?? 'Producto (variante #${fila.inventario.varianteId})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (fila.variante != null)
                          Text('${fila.variante!.tallaNombre} · ${fila.variante!.colorNombre}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        if (fila.editando) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(labelText: 'Cantidad', isDense: true, border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  controller: TextEditingController(text: '${fila.cantidadEdit}'),
                                  onChanged: (v) => fila.cantidadEdit = int.tryParse(v) ?? 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(labelText: 'Reservada', isDense: true, border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  controller: TextEditingController(text: '${fila.reservadaEdit}'),
                                  onChanged: (v) => fila.reservadaEdit = int.tryParse(v) ?? 0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(onPressed: () => setState(() => fila.editando = false), child: const Text('Cancelar')),
                              FilledButton(onPressed: () => _guardarFila(fila), child: const Text('Guardar')),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _dato('Cantidad', '${fila.inventario.cantidad}'),
                              _dato('Reservada', '${fila.inventario.cantidadReservada}'),
                              _dato(
                                'Disponible',
                                '${fila.inventario.disponible}',
                                color: fila.inventario.disponible == 0 ? Colors.red : Colors.green.shade700,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(onPressed: () => _editarFila(fila), child: const Text('Editar')),
                              TextButton(
                                onPressed: () => _eliminarFila(fila),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dato(String etiqueta, String valor, {Color? color}) => Column(
        children: [
          Text(etiqueta, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(valor, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      );

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
