import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/sesion.dart';
import '../core/theme.dart';
import '../services/api_client.dart';
import '../widgets/sesion_expirada_view.dart';

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
  List<dynamic> _planes = const [];

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
      final results = await Future.wait([
        http.get(ApiClient.uri('/empresas'), headers: ApiClient.authHeaders()),
        http.get(ApiClient.uri('/suscripciones/planes'), headers: ApiClient.authHeaders()),
      ]);
      final res = results[0];
      final resPlanes = results[1];

      if (ApiClient.esErrorAuth(res) || ApiClient.esErrorAuth(resPlanes)) {
        await ApiClient.manejarErrorAuth();
      }

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = ApiClient.mensajeHttp(res, fallback: 'No se pudieron cargar las empresas');
        // ignore: avoid_print
        print('[AdminEmpresasPage] $msg');
        throw Exception(msg);
      }

      List<dynamic> planes = const [];
      if (resPlanes.statusCode >= 200 && resPlanes.statusCode < 300) {
        final decodedPlanes = jsonDecode(resPlanes.body);
        planes = decodedPlanes is List ? decodedPlanes : const [];
      }

      final decoded = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        _empresas = decoded is List ? decoded : const [];
        _planes = planes;
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
          onPressed: _abrirFormularioNuevaEmpresa,
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
        onPressed: _abrirFormularioNuevaEmpresa,
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

  Future<void> _abrirFormularioNuevaEmpresa() async {
    if (_planes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar los planes. Reintenta.'), backgroundColor: Colors.red),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioNuevaEmpresa(planes: _planes.cast<Map<String, dynamic>>()),
    );
    _cargar();
  }
}

/// Formulario simple de registro de nueva empresa (POST /api/empresas).
class _FormularioNuevaEmpresa extends StatefulWidget {
  final List<Map<String, dynamic>> planes;
  const _FormularioNuevaEmpresa({required this.planes});

  @override
  State<_FormularioNuevaEmpresa> createState() => _FormularioNuevaEmpresaState();
}

class _FormularioNuevaEmpresaState extends State<_FormularioNuevaEmpresa> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _nitCtrl = TextEditingController();
  final _adminNombreCtrl = TextEditingController();
  final _adminApellidoCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPasswordCtrl = TextEditingController();

  int? _planId;
  bool _creandoAdmin = false;
  bool _guardando = false;
  String _error = '';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nitCtrl.dispose();
    _adminNombreCtrl.dispose();
    _adminApellidoCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_planId == null) {
      setState(() => _error = 'Selecciona un plan inicial.');
      return;
    }

    setState(() {
      _guardando = true;
      _error = '';
    });

    try {
      final body = <String, dynamic>{
        'nombre_empresa': _nombreCtrl.text.trim(),
        'plan_id': _planId,
        'nit': _nitCtrl.text.trim().isEmpty ? null : _nitCtrl.text.trim(),
      };
      if (_creandoAdmin) {
        body['admin_nombre'] = _adminNombreCtrl.text.trim();
        body['admin_apellido'] = _adminApellidoCtrl.text.trim();
        body['admin_email'] = _adminEmailCtrl.text.trim();
        body['admin_password'] = _adminPasswordCtrl.text;
      }

      final res = await http.post(
        ApiClient.uri('/empresas'),
        headers: ApiClient.jsonHeaders(),
        body: jsonEncode(body..removeWhere((k, v) => v == null)),
      );
      if (!mounted) return;
      if (ApiClient.esErrorAuth(res)) {
        await ApiClient.manejarErrorAuth();
      }
      if (!mounted) return;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        setState(() {
          _guardando = false;
          _error = ApiClient.mensajeHttp(res, fallback: 'No se pudo registrar la empresa');
        });
        return;
      }
      if (mounted) Navigator.of(context).pop();
    } on SesionExpiradaException {
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Registrar nueva empresa', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 4),
              Text('Se creará con el plan seleccionado y 30 días de vigencia.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre de la empresa', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nitCtrl,
                decoration: const InputDecoration(
                  labelText: 'NIT (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _planId,
                decoration: const InputDecoration(labelText: 'Plan inicial', border: OutlineInputBorder()),
                items: widget.planes
                    .map((p) => DropdownMenuItem(
                          value: (p['id'] as num?)?.toInt(),
                          child: Text('${p['nombre']} · Bs ${(p['precio_mensual'] ?? 0).toStringAsFixed(0)}/mes'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _planId = v),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                value: _creandoAdmin,
                onChanged: (v) => setState(() => _creandoAdmin = v),
                title: const Text('Crear administrador inicial', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Opcional: usuario admin de la nueva empresa', style: TextStyle(fontSize: 12)),
                contentPadding: EdgeInsets.zero,
              ),
              if (_creandoAdmin) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _adminNombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder(), isDense: true),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _adminApellidoCtrl,
                        decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder(), isDense: true),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _adminEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email del admin', border: OutlineInputBorder(), isDense: true),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _adminPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder(), isDense: true),
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 8),
              ],
              if (_error.isNotEmpty) ...[
                Text(_error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
              ],
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_business),
                label: Text(_guardando ? 'Registrando...' : 'Registrar empresa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
