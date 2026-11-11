import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/sesion.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/pedidos_service.dart';
import '../services/reservas_service.dart';
import '../services/sucursales_service.dart';
import '../services/usuarios_service.dart';
import '../shared/admin_shell.dart';
import '../widgets/sesion_expirada_view.dart';

// ============================================================
// CU21 - Gestionar Pedido
// CU24 - Gestionar Reservas
// CU20 - Nota de Venta (comprobante del pedido)
// RF10 - Registrar y gestionar reservas
//
// [Rediseño 2.9] Tablas con scroll horizontal: pedidos con
// Cliente (resuelto vía /api/usuarios), Fecha, Total, Estado,
// Acción y Comprobante (GET /api/pagos/pedido/{id} → diálogo
// con el recibo). Reservas con Cliente, Sucursal, Fecha y Estado.
// ============================================================
class AdminOperacionesPage extends StatefulWidget {
  final bool embedded;
  const AdminOperacionesPage({super.key, this.embedded = false});

  @override
  State<AdminOperacionesPage> createState() => _AdminOperacionesPageState();
}

class _AdminOperacionesPageState extends State<AdminOperacionesPage> {
  final pedidosService = PedidosService();
  final reservasService = ReservasService();
  final sucursalesService = SucursalesService();
  final usuariosService = UsuariosService();

  List<Pedido> pedidos = [];
  List<Reserva> reservas = [];
  List<Sucursal> sucursales = [];
  Map<int, Usuario> usuarios = {};

  bool cargando = true;
  String error = '';
  String mensaje = '';
  bool sesionExpirada = false;

  final estadosPedido = const ['pendiente', 'pagado', 'procesando', 'enviado', 'entregado', 'cancelado'];
  final estadosReserva = const ['pendiente', 'confirmada', 'completada', 'cancelada'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      cargando = true;
      error = '';
      sesionExpirada = false;
    });
    try {
      final resultados = await Future.wait([
        pedidosService.listarTodos(),
        reservasService.listarTodas(),
        sucursalesService.listar(soloActivos: false),
      ]);

      // [Rediseño 2.9] Nombres de cliente vía /api/usuarios.
      // Si falla (ej. permisos), la tabla muestra "Usuario #id".
      Map<int, Usuario> mapaUsuarios = {};
      try {
        final lista = await usuariosService.listar();
        mapaUsuarios = {for (final u in lista) u.id: u};
      } catch (e) {
        // ignore: avoid_print
        print('[AdminOperacionesPage] usuarios: $e');
      }

      if (!mounted) return;
      setState(() {
        pedidos = resultados[0] as List<Pedido>;
        reservas = resultados[1] as List<Reserva>;
        sucursales = resultados[2] as List<Sucursal>;
        usuarios = mapaUsuarios;
        cargando = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[AdminOperacionesPage] Error: $e');
      if (!mounted) return;
      setState(() {
        sesionExpirada = e is SesionExpiradaException;
        error = sesionExpirada ? '' : e.toString().replaceFirst('Exception: ', '');
        cargando = false;
      });
    }
  }

  String _nombreSucursal(int id) {
    final s = sucursales.where((s) => s.id == id);
    return s.isEmpty ? 'Sucursal #$id' : s.first.nombre;
  }

  String _nombreCliente(int id) {
    final u = usuarios[id];
    if (u == null) return 'Usuario #$id';
    return '${u.nombre} ${u.apellido}'.trim();
  }

  String _fechaCorta(String fecha) {
    if (fecha.length >= 10) return fecha.substring(0, 10);
    return fecha;
  }

  Color _colorEstadoPedido(String estado) {
    switch (estado) {
      case 'pagado':
        return Colors.blue.shade700;
      case 'procesando':
        return Colors.orange.shade800;
      case 'enviado':
        return Colors.indigo.shade700;
      case 'entregado':
        return Colors.green.shade700;
      case 'cancelado':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _colorEstadoReserva(String estado) {
    switch (estado) {
      case 'confirmada':
        return Colors.blue.shade700;
      case 'completada':
        return Colors.green.shade700;
      case 'cancelada':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  Future<void> _cambiarEstadoPedido(Pedido pedido, String nuevoEstado) async {
    try {
      await pedidosService.cambiarEstado(pedido.id, nuevoEstado);
      setState(() => mensaje = 'Pedido #${pedido.id} actualizado a "$nuevoEstado".');
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _cambiarEstadoReserva(Reserva reserva, String nuevoEstado) async {
    try {
      await reservasService.cambiarEstado(reserva.id, nuevoEstado);
      setState(() => mensaje = 'Reserva #${reserva.id} actualizada a "$nuevoEstado".');
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // CU20 - Nota de Venta: consulta los pagos del pedido y muestra
  // el comprobante en un diálogo (GET /api/pagos/pedido/{id}).
  Future<void> _verComprobante(Pedido pedido) async {
    List<dynamic> pagos = const [];
    try {
      final res = await http.get(
        ApiClient.uri('/pagos/pedido/${pedido.id}'),
        headers: ApiClient.authHeaders(),
      );
      if (ApiClient.esErrorAuth(res)) {
        await ApiClient.manejarErrorAuth();
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        pagos = decoded is List ? decoded : const [];
      }
    } on SesionExpiradaException {
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('[AdminOperacionesPage] comprobante: $e');
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _DialogoComprobante(
        pedido: pedido,
        cliente: _nombreCliente(pedido.usuarioId),
        pagos: pagos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AdminScaffold(
        titulo: 'Pedidos y Reservas',
        embedded: widget.embedded,
        bottom: TabBar(
          tabs: [
            Tab(text: 'Pedidos (${pedidos.length})'),
            Tab(text: 'Reservas (${reservas.length})'),
          ],
        ),
        body: cargando
            ? const Center(child: CircularProgressIndicator())
            : sesionExpirada
                ? SesionExpiradaView(onReintentar: _cargar)
                : Column(
                    children: [
                      if (mensaje.isNotEmpty) _banner(mensaje, Colors.green),
                      if (error.isNotEmpty) _banner(error, Colors.red),
                      Expanded(
                        child: TabBarView(
                          children: [_tabPedidos(), _tabReservas()],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _banner(String texto, Color color) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );

  // ============== TAB PEDIDOS ==============
  Widget _tabPedidos() {
    if (pedidos.isEmpty) {
      return const Center(child: Text('No hay pedidos registrados.', style: TextStyle(color: Colors.grey)));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: DataTable(
            headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black87),
            dataTextStyle: const TextStyle(fontSize: 12.5),
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('ID'), numeric: true),
              DataColumn(label: Text('Cliente')),
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Total'), numeric: true),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Acción')),
            ],
            rows: pedidos.map((pedido) {
              final finalizado = pedido.estado == 'cancelado' || pedido.estado == 'entregado';
              return DataRow(cells: [
                DataCell(Text('#${pedido.id}', style: const TextStyle(fontWeight: FontWeight.w700))),
                DataCell(
                  SizedBox(
                    width: 160,
                    child: Text(_nombreCliente(pedido.usuarioId), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(Text(_fechaCorta(pedido.fechaPedido))),
                DataCell(Text('Bs ${pedido.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700))),
                DataCell(_chipEstado(pedido.estado, _colorEstadoPedido(pedido.estado))),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!finalizado)
                        PopupMenuButton<String>(
                          tooltip: 'Cambiar estado',
                          icon: const Icon(Icons.published_with_changes_outlined, size: 20),
                          onSelected: (v) => _cambiarEstadoPedido(pedido, v),
                          itemBuilder: (_) => estadosPedido
                              .where((e) => e != pedido.estado)
                              .map((e) => PopupMenuItem(value: e, child: Text(e)))
                              .toList(),
                        )
                      else
                        const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                      IconButton(
                        icon: const Icon(Icons.receipt_long_outlined, size: 20, color: AppTheme.bronce),
                        tooltip: 'Ver comprobante',
                        onPressed: () => _verComprobante(pedido),
                      ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============== TAB RESERVAS ==============
  Widget _tabReservas() {
    if (reservas.isEmpty) {
      return const Center(child: Text('No hay reservas registradas.', style: TextStyle(color: Colors.grey)));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: DataTable(
            headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black87),
            dataTextStyle: const TextStyle(fontSize: 12.5),
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('ID'), numeric: true),
              DataColumn(label: Text('Cliente')),
              DataColumn(label: Text('Sucursal')),
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Acción')),
            ],
            rows: reservas.map((reserva) {
              final finalizada = reserva.estado == 'cancelada' || reserva.estado == 'completada';
              return DataRow(cells: [
                DataCell(Text('#${reserva.id}', style: const TextStyle(fontWeight: FontWeight.w700))),
                DataCell(
                  SizedBox(
                    width: 160,
                    child: Text(_nombreCliente(reserva.usuarioId), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(Text(_nombreSucursal(reserva.sucursalId))),
                DataCell(Text(_fechaCorta(reserva.fechaReserva))),
                DataCell(_chipEstado(reserva.estado, _colorEstadoReserva(reserva.estado))),
                DataCell(
                  finalizada
                      ? const Icon(Icons.lock_outline, size: 16, color: Colors.grey)
                      : PopupMenuButton<String>(
                          tooltip: 'Cambiar estado',
                          icon: const Icon(Icons.published_with_changes_outlined, size: 20),
                          onSelected: (v) => _cambiarEstadoReserva(reserva, v),
                          itemBuilder: (_) => estadosReserva
                              .where((e) => e != reserva.estado)
                              .map((e) => PopupMenuItem(value: e, child: Text(e)))
                              .toList(),
                        ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _chipEstado(String estado, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// CU20 - Nota de Venta: diálogo con el comprobante del pedido.
class _DialogoComprobante extends StatelessWidget {
  final Pedido pedido;
  final String cliente;
  final List<dynamic> pagos;

  const _DialogoComprobante({required this.pedido, required this.cliente, required this.pagos});

  String _fmtFecha(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    return s.length >= 16 ? s.substring(0, 16).replaceFirst('T', ' ') : s;
  }

  String _fmtMonto(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
    return 'Bs. ${n.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.receipt_long, color: AppTheme.bronce),
          const SizedBox(width: 8),
          const Text('Comprobante', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del recibo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.negro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MENSTYLE', style: TextStyle(color: AppTheme.amarilloMarca, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  Text('Nota de Venta · Pedido #${pedido.id}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _fila('Cliente', cliente),
            _fila('Fecha', _fmtFecha(pedido.fechaPedido)),
            _fila('Estado', pedido.estado),
            _fila('Total', _fmtMonto(pedido.total)),
            _fila('Ítems', '${pedido.detalles.length}'),
            const Divider(height: 24),
            if (pagos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Este pedido aún no tiene pagos registrados.',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              )
            else ...[
              const Text('Pagos registrados', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final p in pagos)
                _tilePago((p as Map).cast<String, dynamic>()),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(etiqueta, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _tilePago(Map<String, dynamic> pago) {
    final metodo = (pago['metodo'] ?? '—').toString();
    final monto = _fmtMonto(pago['monto']);
    final estado = (pago['estado'] ?? '—').toString();
    final referencia = (pago['referencia'] ?? '').toString();
    final fecha = _fmtFecha(pago['fecha_pago']);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(metodo, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text(monto, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 2),
          Text('Estado: $estado · $fecha', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          if (referencia.isNotEmpty)
            Text('Ref: $referencia', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
