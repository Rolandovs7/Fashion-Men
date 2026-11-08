import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/sesion.dart';
import '../services/api_client.dart';
import '../widgets/sesion_expirada_view.dart';

/// Dashboard ejecutivo para Administrador/SuperAdmin.
/// Consume GET /api/reportes/dashboard (DashboardResponse).
class AdminDashboardPage extends StatefulWidget {
  final bool embedded;
  const AdminDashboardPage({super.key, this.embedded = false});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _cargando = true;
  bool _sesionExpirada = false;
  String _error = '';
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = '';
      _sesionExpirada = false;
    });
    try {
      final res = await http.get(
        ApiClient.uri('/reportes/dashboard'),
        headers: ApiClient.authHeaders(),
      );
      if (ApiClient.esErrorAuth(res)) {
        await ApiClient.manejarErrorAuth();
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = ApiClient.mensajeHttp(res, fallback: 'No se pudo cargar el dashboard');
        // ignore: avoid_print
        print('[AdminDashboardPage] $msg');
        throw Exception(msg);
      }
      final decoded = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        _data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        _cargando = false;
      });
    } on SesionExpiradaException {
      if (!mounted) return;
      setState(() {
        _sesionExpirada = true;
        _cargando = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[AdminDashboardPage] Error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: content,
    );
  }

  Widget _buildContent() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_sesionExpirada) return SesionExpiradaView(onReintentar: _cargar);
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    final d = _data ?? const {};
    final totalVentas = (d['total_ventas'] as num?)?.toDouble() ?? 0;
    final totalPedidos = (d['total_pedidos'] as num?)?.toInt() ?? 0;
    final totalProductos = (d['total_productos'] as num?)?.toInt() ?? 0;
    final totalSucursales = (d['total_sucursales'] as num?)?.toInt() ?? 0;
    final bajoStock = (d['productos_bajo_stock'] as num?)?.toInt() ?? 0;
    final clientes = (d['clientes_registrados'] as num?)?.toInt() ?? 0;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Métricas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Resumen del negocio',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          _kpiCard(
            icon: Icons.payments_outlined,
            color: Colors.green,
            label: 'Total ventas',
            value: 'Bs. ${totalVentas.toStringAsFixed(2)}',
          ),
          _kpiCard(
            icon: Icons.receipt_long_outlined,
            color: Colors.blue,
            label: 'Pedidos',
            value: '$totalPedidos',
          ),
          Row(
            children: [
              Expanded(
                child: _kpiSmall(
                  icon: Icons.checkroom_outlined,
                  label: 'Productos',
                  value: '$totalProductos',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiSmall(
                  icon: Icons.store_outlined,
                  label: 'Sucursales',
                  value: '$totalSucursales',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _kpiSmall(
                  icon: Icons.warning_amber_rounded,
                  label: 'Bajo stock',
                  value: '$bajoStock',
                  highlight: bajoStock > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiSmall(
                  icon: Icons.people_outline,
                  label: 'Clientes',
                  value: '$clientes',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiSmall({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: highlight ? Colors.orange : Colors.black54),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: highlight ? Colors.orange.shade800 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
