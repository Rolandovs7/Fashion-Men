import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/reservas_service.dart';
import '../services/sucursales_service.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';

class MisReservasPage extends StatefulWidget {
  const MisReservasPage({super.key});

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
        error = 'Inicia sesión para ver tus reservas.';
      });
      return;
    }

    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final resultados = await Future.wait([
        reservasService.listarMisReservas(),
        sucursalesService.listar(),
      ]);

      setState(() {
        reservas = resultados[0] as List<Reserva>;
        sucursales = resultados[1] as List<Sucursal>;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudieron cargar tus reservas.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoReservas,
      appBar: AppBar(title: const Text('Mis reservas')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
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
                  ...reservas.map(
                    (reserva) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reserva #${reserva.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _colorEstado(reserva.estado)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    etiquetas[reserva.estado] ?? reserva.estado,
                                    style: TextStyle(
                                      color: _colorEstado(reserva.estado),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_nombreSucursal(reserva.sucursalId)} · ${reserva.fechaReserva.substring(0, 16).replaceFirst('T', ' ')}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const Divider(height: 20),
                            ...reserva.detalles.map(
                              (d) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Variante #${d.varianteId}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    Text(
                                      '${d.cantidad} unid.',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (reserva.observaciones?.isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Text(
                                '"${reserva.observaciones}"',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (_puedeCancelar(reserva)) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _cancelar(reserva),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Cancelar reserva'),
                                ),
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
