import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/sesion.dart';
import '../services/api_client.dart';
import '../widgets/sesion_expirada_view.dart';

/// Lista de empresas (tenants). Solo SuperAdmin.
/// Consume GET /api/empresas (EmpresaListadoRead[]).
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

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Empresas (Tenants)')),
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
        padding: const EdgeInsets.all(12),
        itemCount: _empresas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final e = _empresas[i] as Map? ?? const {};
          final id = e['id'];
          final nombre = (e['nombre'] ?? 'Empresa').toString();
          final plan = (e['plan_actual'] ?? 'Sin plan').toString();
          final fecha = _fmtFecha(e['fecha_registro']);
          final activo = e['activo'] == true;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.black,
                child: Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('ID: $id · Plan: $plan · Registro: $fecha'),
              trailing: Chip(
                label: Text(activo ? 'Activo' : 'Inactivo'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          );
        },
      ),
    );
  }
}
