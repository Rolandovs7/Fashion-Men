import 'package:flutter/material.dart';
import '../core/sesion.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/catalogo_service.dart';
import '../services/inventario_service.dart';
import '../services/sucursales_service.dart';
import '../shared/admin_shell.dart';
import '../widgets/sesion_expirada_view.dart';

// ============================================================
// CU15 - Pantalla de Gestión de Inventario
// RF20 - Actualizar automáticamente el inventario tras una venta
// RF21 - Controlar las existencias por sucursal
// RF22 - Registrar movimientos de inventario
// Equivalente a admin-inventario (Angular). Selecciona sucursal,
// muestra stock por variante (talla/color), permite registrar,
// editar y eliminar. Mismos endpoints /api/inventario que Angular.
//
// [Rediseño 2.8] Tabla horizontal (DataTable) con columnas
// Producto, Código, Categoría, Stock, Stock Mínimo, Precio, Estado
// y Acciones; filtro por sucursal y edición mediante diálogo.
// [Lote fix] Dropdowns expandidos (isExpanded) con ellipsis, columna
// "Código" (antes "SKU") y paginación simple de 20 ítems por página.
// ============================================================
class _FilaInventario {
  final Inventario inventario;
  Variante? variante;
  Producto? producto;
  String? categoriaNombre;

  _FilaInventario(this.inventario);

  int get disponible => inventario.disponible;
  int get stockMinimo => producto?.stockMinimo ?? 5;

  /// Estado de reposición según disponible vs stock mínimo (RF21).
  String get estadoEtiqueta {
    if (disponible <= 0) return 'Sin stock';
    if (disponible < stockMinimo) return 'Bajo mínimo';
    return 'Disponible';
  }

  Color get estadoColor {
    if (disponible <= 0) return Colors.red.shade700;
    if (disponible < stockMinimo) return Colors.orange.shade800;
    return Colors.green.shade700;
  }
}

class AdminInventarioPage extends StatefulWidget {
  final bool embedded;
  const AdminInventarioPage({super.key, this.embedded = false});

  @override
  State<AdminInventarioPage> createState() => _AdminInventarioPageState();
}

class _AdminInventarioPageState extends State<AdminInventarioPage> {
  /// [Lote fix] Paginación simple: máximo 20 registros por página.
  static const int _porPagina = 20;
  int _paginaActual = 1;

  final inventarioService = InventarioService();
  final sucursalesService = SucursalesService();
  final catalogoService = CatalogoService();

  List<Sucursal> sucursales = [];
  List<Producto> productos = [];
  List<Categoria> categorias = [];
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
  bool sesionExpirada = false;

  @override
  void initState() {
    super.initState();
    _cargarInicial();
  }

  Future<void> _cargarInicial() async {
    try {
      final resultados = await Future.wait([
        sucursalesService.listar(),
        catalogoService.listarProductos(),
        catalogoService.listarCategorias(),
      ]);

      if (!mounted) return;
      setState(() {
        sucursales = resultados[0] as List<Sucursal>;
        productos = (resultados[1] as List<Producto>).where((p) => p.activo).toList();
        categorias = resultados[2] as List<Categoria>;
      });

      if (sucursales.isNotEmpty) {
        sucursalSeleccionadaId = sucursales.first.id;
        await _cargarInventario();
      } else {
        setState(() => cargando = false);
      }
    } catch (e) {
      // ignore: avoid_print
      print('[AdminInventarioPage] Error inicial: $e');
      if (!mounted) return;
      setState(() {
        sesionExpirada = e is SesionExpiradaException;
        error = sesionExpirada ? '' : e.toString().replaceFirst('Exception: ', '');
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
      sesionExpirada = false;
    });

    try {
      final inventarios = await inventarioService.listar(sucursalId: sucursalSeleccionadaId);
      await _resolverFilas(inventarios);
    } catch (e) {
      // ignore: avoid_print
      print('[AdminInventarioPage] Error inventario: $e');
      if (!mounted) return;
      setState(() {
        sesionExpirada = e is SesionExpiradaException;
        error = sesionExpirada ? '' : e.toString().replaceFirst('Exception: ', '');
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
          if (fila.producto != null) {
            final cat = categorias.where((c) => c.id == fila.producto!.categoriaId);
            fila.categoriaNombre = cat.isEmpty ? '—' : cat.first.nombre;
          }
        }
      } catch (_) {
        // Si no se puede resolver el nombre, igual se muestra la fila con el ID.
      }
      nuevasFilas.add(fila);
    }

    if (!mounted) return;
    setState(() {
      filas = nuevasFilas;
      cargando = false;
      // [Lote fix] Al recargar, se vuelve a la primera página.
      _paginaActual = 1;
    });
  }

  // ==========================================================
  // [Lote fix] Paginación simple (20 registros por página)
  // ==========================================================
  int get _totalPaginas =>
      filas.isEmpty ? 1 : (filas.length / _porPagina).ceil();

  int get _pagina => _paginaActual.clamp(1, _totalPaginas);

  List<_FilaInventario> get _filasVisibles {
    if (filas.isEmpty) return const [];
    final inicio = (_pagina - 1) * _porPagina;
    var fin = inicio + _porPagina;
    if (fin > filas.length) fin = filas.length;
    return filas.sublist(inicio, fin);
  }

  Future<void> _cargarVariantesDelProducto(int? productoId) async {
    setState(() {
      productoSeleccionadoId = productoId;
      varianteSeleccionadaId = null;
      variantesDelProducto = [];
    });

    if (productoId == null) return;

    final variantes = await catalogoService.listarVariantesPorProducto(productoId);
    if (!mounted) return;
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

  // CU15 / RF22 - [Rediseño 2.8] Edición por diálogo (cantidad/reservada)
  Future<void> _editarFilaDialogo(_FilaInventario fila) async {
    final cantidadCtrl = TextEditingController(text: '${fila.inventario.cantidad}');
    final reservadaCtrl = TextEditingController(text: '${fila.inventario.cantidadReservada}');

    final guardar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar inventario', style: TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fila.producto?.nombre ?? 'Producto (variante #${fila.inventario.varianteId})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (fila.variante != null)
                Text(
                  '${fila.variante!.tallaNombre} · ${fila.variante!.colorNombre}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad total',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reservadaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad reservada',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Guardar')),
        ],
      ),
    );

    if (guardar != true) return;

    final cantidad = int.tryParse(cantidadCtrl.text.trim());
    final reservada = int.tryParse(reservadaCtrl.text.trim());
    if (cantidad == null || reservada == null || reservada > cantidad) {
      setState(() => error = 'La cantidad reservada no puede ser mayor que la cantidad total.');
      return;
    }

    try {
      await inventarioService.actualizar(
        fila.inventario.id,
        cantidad: cantidad,
        cantidadReservada: reservada,
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
      embedded: widget.embedded,
      body: sesionExpirada
          ? SesionExpiradaView(onReintentar: _cargarInicial)
          : RefreshIndicator(
              onRefresh: _cargarInventario,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (mensaje.isNotEmpty) _banner(mensaje, Colors.green),
                  if (error.isNotEmpty) _banner(error, Colors.red),

                  // [Rediseño 2.8] Filtro por sucursal
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.store_outlined, size: 18, color: AppTheme.bronce),
                              const SizedBox(width: 6),
                              const Text('Sucursal', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // [Lote fix] isExpanded + ellipsis para que el texto
                          // no desborde el recuadro del dropdown.
                          DropdownButtonFormField<int>(
                            initialValue: sucursalSeleccionadaId,
                            isExpanded: true,
                            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                            items: sucursales
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      '${s.nombre} — ${s.ciudad}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
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

                  // Registrar stock (CU15 / RF22)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.add_box_outlined, size: 18, color: AppTheme.bronce),
                              const SizedBox(width: 6),
                              const Text('Registrar stock', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int>(
                            initialValue: productoSeleccionadoId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Producto', border: OutlineInputBorder(), isDense: true),
                            items: productos
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(
                                      p.nombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _cargarVariantesDelProducto,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: varianteSeleccionadaId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Talla / Color', border: OutlineInputBorder(), isDense: true),
                            items: variantesDelProducto
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v.id,
                                    child: Text(
                                      '${v.tallaNombre} · ${v.colorNombre}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
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
                            'Si la variante ya tiene stock en esta sucursal, edítala en la tabla.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // [Rediseño 2.8] Tabla de inventario con scroll horizontal
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
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black87),
                          dataTextStyle: const TextStyle(fontSize: 12.5),
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('Producto')),
                            DataColumn(label: Text('Código')),
                            DataColumn(label: Text('Categoría')),
                            DataColumn(label: Text('Stock'), numeric: true),
                            DataColumn(label: Text('Stock Mínimo'), numeric: true),
                            DataColumn(label: Text('Precio'), numeric: true),
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: _filasVisibles.map((fila) {
                            final producto = fila.producto;
                            return DataRow(cells: [
                              DataCell(
                                SizedBox(
                                  width: 180,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        producto?.nombre ?? 'Producto (variante #${fila.inventario.varianteId})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      if (fila.variante != null)
                                        Text(
                                          '${fila.variante!.tallaNombre} · ${fila.variante!.colorNombre}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  fila.variante?.sku ?? 'MS-P${fila.variante?.productoId ?? '-'}-T${fila.variante?.tallaId ?? '-'}-C${fila.variante?.colorId ?? '-'}',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                              DataCell(Text(fila.categoriaNombre ?? '—')),
                              DataCell(Text('${fila.inventario.cantidad}')),
                              DataCell(Text('${fila.stockMinimo}')),
                              DataCell(Text(producto == null ? '—' : 'Bs ${producto.precio.toStringAsFixed(2)}')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: fila.estadoColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    fila.estadoEtiqueta,
                                    style: TextStyle(color: fila.estadoColor, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      tooltip: 'Editar cantidades',
                                      onPressed: () => _editarFilaDialogo(fila),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      tooltip: 'Eliminar registro',
                                      onPressed: () => _eliminarFila(fila),
                                    ),
                                  ],
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  if (filas.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _paginacion(),
                  ],
                ],
              ),
            ),
    );
  }

  // [Lote fix] Controles de paginación: 20 registros por página.
  Widget _paginacion() {
    if (_totalPaginas <= 1) {
      return Center(
        child: Text(
          '${filas.length} registros',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: _pagina > 1
              ? () => setState(() => _paginaActual = _pagina - 1)
              : null,
          icon: const Icon(Icons.chevron_left, size: 18),
          label: const Text('Anterior'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Página $_pagina de $_totalPaginas · ${filas.length} registros',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton(
          onPressed: _pagina < _totalPaginas
              ? () => setState(() => _paginaActual = _pagina + 1)
              : null,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text('Siguiente'), Icon(Icons.chevron_right, size: 18)],
          ),
        ),
      ],
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
