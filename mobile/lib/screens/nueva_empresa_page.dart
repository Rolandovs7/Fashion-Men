import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/sesion.dart';
import '../core/theme.dart';
import '../services/api_client.dart';
import '../widgets/sesion_expirada_view.dart';

/// [SaaS] Pantalla completa para registrar una nueva empresa (tenant).
/// Consume GET /api/suscripciones/planes y POST /api/empresas.
///
/// Reemplaza al antiguo bottom sheet: en pantallas pequeñas el formulario
/// completo no cabía y el dropdown de planes podía fallar al convertir
/// `precio_mensual` (String en el JSON) con `toStringAsFixed`.
class NuevaEmpresaPage extends StatefulWidget {
  const NuevaEmpresaPage({super.key});

  @override
  State<NuevaEmpresaPage> createState() => _NuevaEmpresaPageState();
}

class _NuevaEmpresaPageState extends State<NuevaEmpresaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _nitCtrl = TextEditingController();
  final _adminNombreCtrl = TextEditingController();
  final _adminApellidoCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPasswordCtrl = TextEditingController();

  List<Map<String, dynamic>> _planes = const [];
  int? _planId;
  bool _creandoAdmin = false;
  bool _guardando = false;
  bool _cargandoPlanes = true;
  bool _sesionExpirada = false;
  String _errorPlanes = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargarPlanes();
  }

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

  /// `precio_mensual` puede venir como String ("59.00") o num.
  static double _numero(dynamic valor) {
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor?.toString() ?? '') ?? 0;
  }

  Future<void> _cargarPlanes() async {
    if (!mounted) return;
    setState(() {
      _cargandoPlanes = true;
      _errorPlanes = '';
      _sesionExpirada = false;
    });

    try {
      final res = await http.get(
        ApiClient.uri('/suscripciones/planes'),
        headers: ApiClient.authHeaders(),
      );
      if (!mounted) return;
      if (ApiClient.esErrorAuth(res)) {
        await ApiClient.manejarErrorAuth();
      }
      if (!mounted) return;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception(
          ApiClient.mensajeHttp(res, fallback: 'No se pudieron cargar los planes'),
        );
      }

      final decoded = jsonDecode(res.body);
      final planes = <Map<String, dynamic>>[];
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            planes.add(Map<String, dynamic>.from(item));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _planes = planes;
        _planId = null;
        _cargandoPlanes = false;
      });
    } on SesionExpiradaException {
      if (!mounted) return;
      setState(() {
        _sesionExpirada = true;
        _cargandoPlanes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorPlanes = e.toString().replaceFirst('Exception: ', '');
        _cargandoPlanes = false;
      });
    }
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
          _error = ApiClient.mensajeHttp(
            res,
            fallback: 'No se pudo registrar la empresa',
          );
        });
        return;
      }

      // Devuelve true para que la lista se refresque y muestre la empresa.
      Navigator.of(context).pop(true);
    } on SesionExpiradaException {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _sesionExpirada = true;
      });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar nueva empresa')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargandoPlanes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sesionExpirada) {
      return SesionExpiradaView(onReintentar: _cargarPlanes);
    }
    if (_errorPlanes.isNotEmpty) {
      return _estadoConReintento(
        icono: Icons.cloud_off_outlined,
        mensaje: _errorPlanes,
      );
    }
    if (_planes.isEmpty) {
      return _estadoConReintento(
        icono: Icons.inventory_2_outlined,
        mensaje: 'No hay planes disponibles. Reintenta en unos segundos.',
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.fondoClaro,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade700),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'La empresa se creará con el plan seleccionado y 30 días de vigencia.',
                    style: TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Datos de la empresa',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nombreCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nombre de la empresa *',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Ingresa el nombre' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nitCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'NIT (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _planId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Plan inicial *',
              border: OutlineInputBorder(),
            ),
            items: _planes
                .map(
                  (p) => DropdownMenuItem<int>(
                    value: (p['id'] as num?)?.toInt(),
                    child: Text(
                      '${p['nombre'] ?? 'Plan'} · Bs ${_numero(p['precio_mensual']).toStringAsFixed(0)}/mes',
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _planId = v),
            validator: (v) => v == null ? 'Selecciona un plan' : null,
          ),
          const SizedBox(height: 22),
          const Text(
            'Administrador inicial (opcional)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            value: _creandoAdmin,
            onChanged: (v) => setState(() => _creandoAdmin = v),
            title: const Text(
              'Crear administrador inicial',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text(
              'Usuario admin de la nueva empresa',
              style: TextStyle(fontSize: 12),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (_creandoAdmin) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _adminNombreCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _adminApellidoCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Apellido',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adminEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email del admin',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email inválido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adminPasswordCtrl,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _guardando ? null : _guardar(),
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 8),
          ],
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _error,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_business),
            label: Text(_guardando ? 'Registrando...' : 'Registrar empresa'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.negro,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoConReintento({
    required IconData icono,
    required String mensaje,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 46, color: Colors.grey.shade500),
            const SizedBox(height: 14),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _cargarPlanes,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
