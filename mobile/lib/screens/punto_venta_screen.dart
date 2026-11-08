import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../db/database_helper.dart';
import '../services/offline_sync_service.dart';

/// POS offline básico.
/// - Carga productos desde SQLite local.
/// - Permite armar una venta y presionar "Cobrar".
/// - Guarda la operación con OfflineSyncService para sincronizar cuando haya internet.
class PuntoVentaScreen extends StatefulWidget {
  final bool embedded;
  const PuntoVentaScreen({super.key, this.embedded = false});

  @override
  State<PuntoVentaScreen> createState() => _PuntoVentaScreenState();
}

class _LineaVenta {
  final Map<String, dynamic> producto;
  int cantidad;
  _LineaVenta({required this.producto, this.cantidad = 1});
}

class _PuntoVentaScreenState extends State<PuntoVentaScreen> {
  static const _amarillo = Color(0xFFFFD400);

  final _sync = OfflineSyncService();
  List<Map<String, dynamic>> _productos = [];
  final List<_LineaVenta> _carrito = [];
  bool _cargando = true;
  bool _cobrando = false;
  String _error = '';
  String _mensaje = '';

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _cargando = true;
      _error = '';
    });
    try {
      final rows = await DatabaseHelper.instance.getProductos();
      setState(() {
        _productos = rows;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron cargar productos locales: $e';
        _cargando = false;
      });
    }
  }

  double get _total => _carrito.fold(0.0, (acc, l) {
        final precio = (l.producto['precio'] as num?)?.toDouble() ?? 0.0;
        return acc + precio * l.cantidad;
      });

  void _agregar(Map<String, dynamic> p) {
    final id = p['id'];
    final idx = _carrito.indexWhere((l) => l.producto['id'] == id);
    setState(() {
      if (idx >= 0) {
        _carrito[idx].cantidad += 1;
      } else {
        _carrito.add(_LineaVenta(producto: p, cantidad: 1));
      }
      _mensaje = '';
      _error = '';
    });
  }

  void _cambiarCantidad(int index, int delta) {
    setState(() {
      final nueva = _carrito[index].cantidad + delta;
      if (nueva <= 0) {
        _carrito.removeAt(index);
      } else {
        _carrito[index].cantidad = nueva;
      }
    });
  }

  Future<void> _cobrar() async {
    if (_carrito.isEmpty) {
      setState(() => _error = 'Agrega al menos un producto para cobrar.');
      return;
    }
    setState(() {
      _cobrando = true;
      _error = '';
      _mensaje = '';
    });
    try {
      final productosPayload = _carrito
          .map((l) => {
                'producto_id': l.producto['id'],
                'nombre': l.producto['nombre'],
                'cantidad': l.cantidad,
                'precio_unitario': (l.producto['precio'] as num?)?.toDouble() ?? 0.0,
              })
          .toList();

      final operacion = <String, dynamic>{
        'tipo': 'venta',
        'productos': productosPayload,
        'monto': _total,
        'sucursal_id': null,
        'datosExtra': {
          'origen': 'pos_offline_flutter',
          'fecha_local': DateTime.now().toIso8601String(),
        },
      };

      final uuid = await _sync.guardarOperacionOffline(operacion);
      if (!mounted) return;
      setState(() {
        _cobrando = false;
        _carrito.clear();
        _mensaje =
            'Venta guardada localmente (offline). Se sincronizará al recuperar conexión.\nID: $uuid';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cobrando = false;
        _error = 'No se pudo guardar la venta offline: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoCatalogo,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Punto de Venta (Offline)'),
              backgroundColor: AppTheme.negro,
              foregroundColor: _amarillo,
              actions: [
                IconButton(
                  onPressed: _cargarProductos,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Recargar productos locales',
                ),
              ],
            ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_mensaje.isNotEmpty) _banner(_mensaje, Colors.green),
                if (_error.isNotEmpty) _banner(_error, Colors.red),
                Expanded(
                  child: _productos.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No hay productos en la base local (SQLite).\n'
                              'Sincronizá el catálogo cuando tengas conexión para usar el POS offline.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          children: [
                            const Text(
                              'Productos (local)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.negro,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._productos.map((p) {
                              final nombre = (p['nombre'] ?? 'Producto').toString();
                              final precio = (p['precio'] as num?)?.toDouble() ?? 0.0;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.negro,
                                    foregroundColor: _amarillo,
                                    child: const Icon(Icons.checkroom),
                                  ),
                                  title: Text(
                                    nombre,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text('Bs ${precio.toStringAsFixed(2)}'),
                                  trailing: FilledButton(
                                    onPressed: () => _agregar(p),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _amarillo,
                                      foregroundColor: AppTheme.negro,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    child: const Text('Agregar'),
                                  ),
                                ),
                              );
                            }),
                            if (_carrito.isNotEmpty) ...[
                              const Divider(height: 28),
                              const Text(
                                'Venta actual',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppTheme.negro,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._carrito.asMap().entries.map((e) {
                                final i = e.key;
                                final l = e.value;
                                final nombre = (l.producto['nombre'] ?? 'Producto').toString();
                                final precio = (l.producto['precio'] as num?)?.toDouble() ?? 0.0;
                                return Card(
                                  color: Colors.white,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      'Bs ${precio.toStringAsFixed(2)} x ${l.cantidad} = Bs ${(precio * l.cantidad).toStringAsFixed(2)}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          onPressed: () => _cambiarCantidad(i, -1),
                                        ),
                                        Text('${l.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline),
                                          onPressed: () => _cambiarCantidad(i, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                ),
                if (_carrito.isNotEmpty)
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              Text(
                                'Bs ${_total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  color: AppTheme.negro,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _cobrando ? null : _cobrar,
                              icon: _cobrando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.negro,
                                      ),
                                    )
                                  : const Icon(Icons.payments_outlined),
                              label: Text(_cobrando ? 'Guardando...' : 'Cobrar (guardar offline)'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _amarillo,
                                foregroundColor: AppTheme.negro,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _banner(String texto, Color color) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );
}
