import 'package:flutter/material.dart';

import '../core/sesion.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/reservas_service.dart';
import '../services/sucursales_service.dart';
import '../widgets/sesion_expirada_view.dart';

class MisReservasPage extends StatefulWidget {
  final bool embedded;
  const MisReservasPage({super.key, this.embedded = false});

  @override
  State<MisReservasPage> createState() => _MisReservasPageState();
}

class _MisReservasPageState extends State<MisReservasPage> {
  final reservasService = ReservasService();
  final sucursalesService = SucursalesService();

  List<Reserva> reservas = [];
  List<Sucursal> sucursales = [];
  bool cargando = true;
  String error = '';
  String mensaje = '';
  bool sesionExpirada = false;

  final etiquetas = const {
    'pendiente': 'Pendiente',
    'confirmada': 'Confirmada',
    'cancelada': 'Cancelada',
    'completada': 'Completada',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

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
      final resultados = await Future.wait([
        reservasService.listarMisReservas(),
        sucursalesService.listar(),
      ]);

      if (!mounted) return;
      setState(() {
        reservas = resultados[0] as List<Reserva>;
        sucursales = resultados[1] as List<Sucursal>;
        cargando = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[MisReservasPage] Error cargando reservas: $e');
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

  bool _puedeCancelar(Reserva r) =>
      !['cancelada', 'completada'].contains(r.estado);

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.amber.shade800;
      case 'confirmada':
        return Colors.blue.shade700;
      case 'completada':
        return Colors.green.shade700;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelar(Reserva reserva) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Cancelar la reserva #${reserva.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await reservasService.cancelar(reserva.id);
      setState(() => mensaje = 'Reserva #${reserva.id} cancelada.');
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// [Rediseño] Card de reserva con bordes redondeados, sombra suave,
  /// estado en chip y acciones alineadas.
  Widget _tarjetaReserva(Reserva reserva) {
    final color = _colorEstado(reserva.estado);
    final puedeCancelar = _puedeCancelar(reserva);
    final fecha = reserva.fechaReserva.length >= 16
        ? reserva.fechaReserva.substring(0, 16).replaceFirst('T', ' ')
        : reserva.fechaReserva;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reserva #${reserva.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.negro,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    etiquetas[reserva.estado] ?? reserva.estado,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.fondoReservas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 17,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fecha,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _nombreSucursal(reserva.sucursalId),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (reserva.detalles.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              for (final d in reserva.detalles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Variante #${d.varianteId}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '${d.cantidad} unid.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (reserva.observaciones?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                '"${reserva.observaciones}"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
            if (puedeCancelar) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _cancelar(reserva),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancelar reserva'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoReservas,
      appBar: widget.embedded ? null : AppBar(title: const Text('Mis reservas')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : sesionExpirada
              ? SesionExpiradaView(
                  mensaje: 'Inicia sesión para ver tus reservas.',
                  onReintentar: _cargar,
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (mensaje.isNotEmpty) _banner(mensaje, Colors.green),
                      if (error.isNotEmpty) _banner(error, Colors.red),
                  if (!cargando && reservas.isEmpty && error.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'Aún no tienes reservas.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ...reservas.map((reserva) => _tarjetaReserva(reserva)),
                ],
              ),
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
    child: Text(
      texto,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );
}
