import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/sesion.dart';
import '../core/theme.dart';
import '../services/api_client.dart';
import '../widgets/sesion_expirada_view.dart';
import 'nueva_empresa_page.dart';

/// Lista de empresas (tenants). Solo SuperAdmin.
/// Consume GET /api/empresas (EmpresaListadoRead[]),
/// PATCH /api/empresas/{id}/estado (activar/desactivar) y
/// POST /api/empresas (registrar nueva empresa).
///
/// [Rediseño 2.4] ListView de Cards con logo (inicial), nombre, NIT,
/// plan, estado Activo/Inactivo y botón para desactivar/activar con
/// diálogo de confirmación. FAB "Registrar nueva empresa".
class AdminEmpresasPage extends StatefulWidget {
  final bool embedded;
  const AdminEmpresasPage({super.key, this.embedded = false});

  @override
  State<AdminEmpresasPage> createState() => _AdminEmpresasPageState();
}

class _AdminEmpresasPageState extends State<AdminEmpresasPage> {
  bool _cargando = true;
  bool _sesionExpirada = false;
  String _error = '';
  List<dynamic> _empresas = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = '';
      _sesionExpirada = false;
    });
    try {
      final res = await http.get(
        ApiClient.uri('/empresas'),
        headers: ApiClient.authHeaders(),
      );

      if (ApiClient.esErrorAuth(res)) {
        await ApiClient.manejarErrorAuth();
      }

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = ApiClient.mensajeHttp(res, fallback: 'No se pudieron cargar las empresas');
        // ignore: avoid_print
        print('[AdminEmpresasPage] $msg');
        throw Exception(msg);
      }

      final decoded = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        _empresas = decoded is List ? decoded : const [];
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
      print('[AdminEmpresasPage] Error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  String _fmtFecha(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

  // PATCH /api/empresas/{id}/estado — activar/desactivar tenant
  Future<void> _cambiarEstado(Map empresa, bool nuevoActivo) async {
    final id = empresa['id'];
    final nombre = (empresa['nombre'] ?? 'Empresa').toString();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(nuevoActivo ? '¿Activar "$nombre"?' : '¿Desactivar "$nombre"?'),
        content: Text(
          nuevoActivo
              ? 'La empresa volverá a tener acceso a la plataforma.'
              : 'Los usuarios de esta empresa no podrán iniciar sesión ni usar la API hasta que se reactive.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: nuevoActivo ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(nuevoActivo ? 'Activar' : 'Desactivar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final res = await http.patch(
        ApiClient.uri('/empresas/$id/estado'),
        headers: ApiClient.jsonHeaders(),
        body: jsonEncode({'activo': nuevoActivo}),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      if (ApiClient.esErrorAuth(res)) {
        await ApiClient.manejarErrorAuth();
      }
      if (!mounted) return;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = ApiClient.mensajeHttp(res, fallback: 'No se pudo cambiar el estado');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nuevoActivo ? '"$nombre" activada.' : '"$nombre" desactivada.'),
          backgroundColor: Colors.green,
        ),
      );
      await _cargar();
    } on SesionExpiradaException {
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (widget.embedded) {
      return Scaffold(
        body: content,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _abrirNuevaEmpresa,
          icon: const Icon(Icons.add_business),
          label: const Text('Registrar nueva empresa'),
          backgroundColor: AppTheme.negro,
          foregroundColor: Colors.white,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Empresas (Tenants)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNuevaEmpresa,
        icon: const Icon(Icons.add_business),
        label: const Text('Registrar nueva empresa'),
        backgroundColor: AppTheme.negro,
        foregroundColor: Colors.white,
      ),
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
    if (_empresas.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No hay empresas registradas.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: _empresas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final e = _empresas[i] as Map? ?? const {};
          final id = e['id'];
          final nombre = (e['nombre'] ?? 'Empresa').toString();
          final nit = (e['nit'] ?? '').toString().trim();
          final plan = (e['plan_actual'] ?? 'Sin plan').toString();
          final fecha = _fmtFecha(e['fecha_registro']);
          final activo = e['activo'] == true;
          return _cardEmpresa(
            id: id,
            nombre: nombre,
            nit: nit.isEmpty ? '—' : nit,
            plan: plan,
            fecha: fecha,
            activo: activo,
          );
        },
      ),
    );
  }

  Widget _cardEmpresa({
    required dynamic id,
    required String nombre,
    required String nit,
    required String plan,
    required String fecha,
    required bool activo,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: activo ? Colors.green.withValues(alpha: 0.35) : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.negro,
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E',
                    style: const TextStyle(color: AppTheme.amarilloMarca, fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('NIT: $nit', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Chip(
                  label: Text(activo ? 'Activo' : 'Inactivo'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: activo ? Colors.green.withValues(alpha: 0.12) : Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: activo ? Colors.green.shade800 : Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.workspace_premium_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(child: Text(plan, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(fecha, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    activo
                        ? 'La empresa tiene acceso a la plataforma.'
                        : 'Sin acceso: sus usuarios no pueden iniciar sesión.',
                    style: TextStyle(fontSize: 11.5, color: activo ? Colors.grey.shade600 : Colors.red.shade700),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _cambiarEstado({'id': id, 'nombre': nombre}, !activo),
                  icon: Icon(
                    activo ? Icons.block : Icons.check_circle_outline,
                    size: 18,
                    color: activo ? Colors.red : Colors.green,
                  ),
                  label: Text(
                    activo ? 'Desactivar' : 'Activar',
                    style: TextStyle(color: activo ? Colors.red : Colors.green, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirNuevaEmpresa() async {
    final creada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NuevaEmpresaPage()),
    );
    if (!mounted || creada != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Empresa registrada correctamente.'),
        backgroundColor: Colors.green,
      ),
    );
    await _cargar();
  }
}
