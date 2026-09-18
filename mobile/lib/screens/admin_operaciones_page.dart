import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/pedidos_service.dart';
import '../services/reservas_service.dart';
import '../services/sucursales_service.dart';
import '../shared/admin_shell.dart';

// ============================================================
// CU21 - Gestionar Pedido
// CU24 - Gestionar Reservas
// RF: pendiente de confirmar en documentación (relacionado con
// RF15/RF16 - compra web/móvil, y RF10 - registrar y gestionar reservas)
// Cambia el estado de pedidos/reservas de cualquier cliente.
// CU20 (Nota de Venta) aún no está integrado en esta pantalla en
// Flutter — sí existe en Angular (ver ReciboComponent).
// ============================================================
class AdminOperacionesPage extends StatefulWidget {
  const AdminOperacionesPage({super.key});

  @override
  State<AdminOperacionesPage> createState() => _AdminOperacionesPageState();
}

class _AdminOperacionesPageState extends State<AdminOperacionesPage> {
  final pedidosService = PedidosService();
  final reservasService = ReservasService();
  final sucursalesService = SucursalesService();

  List<Pedido> pedidos = [];
  List<Reserva> reservas = [];
  List<Sucursal> sucursales = [];

  bool cargando = true;
  String error = '';
  String mensaje = '';

  final estadosPedido = const ['pendiente', 'pagado', 'procesando', 'enviado', 'entregado', 'cancelado'];
  final estadosReserva = const ['pendiente', 'confirmada', 'completada', 'cancelada'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    try {
      final resultados = await Future.wait([
        pedidosService.listarTodos(),
        reservasService.listarTodas(),
        sucursalesService.listar(soloActivos: false),
      ]);

      setState(() {
        pedidos = resultados[0] as List<Pedido>;
        reservas = resultados[1] as List<Reserva>;
        sucursales = resultados[2] as List<Sucursal>;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudo cargar la información de operaciones.';
        cargando = false;
      });
    }
  }

  String _nombreSucursal(int id) {
    final s = sucursales.where((s) => s.id == id);
    return s.isEmpty ? 'Sucursal #$id' : s.first.nombre;
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AdminScaffold(
        titulo: 'Pedidos y Reservas',
        bottom: TabBar(
          tabs: [
            Tab(text: 'Pedidos (${pedidos.length})'),
            Tab(text: 'Reservas (${reservas.length})'),
          ],
        ),
        body: cargando
            ? const Center(child: CircularProgressIndicator())
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

  Widget _tabPedidos() {
    if (pedidos.isEmpty) {
      return const Center(child: Text('No hay pedidos registrados.', style: TextStyle(color: Colors.grey)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: pedidos.map((pedido) {
        final finalizado = pedido.estado == 'cancelado' || pedido.estado == 'entregado';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido #${pedido.id} · Usuario #${pedido.usuarioId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Bs ${pedido.total.toStringAsFixed(2)} · ${pedido.fechaPedido.substring(0, 10)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: pedido.estado,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, labelText: 'Estado'),
                  items: estadosPedido.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: finalizado ? null : (v) { if (v != null) _cambiarEstadoPedido(pedido, v); },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _tabReservas() {
    if (reservas.isEmpty) {
      return const Center(child: Text('No hay reservas registradas.', style: TextStyle(color: Colors.grey)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: reservas.map((reserva) {
        final finalizada = reserva.estado == 'cancelada' || reserva.estado == 'completada';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reserva #${reserva.id} · Usuario #${reserva.usuarioId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${_nombreSucursal(reserva.sucursalId)} · ${reserva.fechaReserva.substring(0, 16).replaceFirst('T', ' ')}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: reserva.estado,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, labelText: 'Estado'),
                  items: estadosReserva.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: finalizada ? null : (v) { if (v != null) _cambiarEstadoReserva(reserva, v); },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
