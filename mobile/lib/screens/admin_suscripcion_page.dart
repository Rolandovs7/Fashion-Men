import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/sesion.dart';
import '../core/theme.dart';
import '../services/api_client.dart';
import '../widgets/sesion_expirada_view.dart';

/// Mi Suscripción (administrador/superadmin): plan actual, planes disponibles
/// y cambio de plan con pago simulado (POST /suscripciones/confirmar-pago).
///
/// [Rediseño 2.6] Cards con plan actual (fechas, estado, días restantes),
/// historial de pagos (GET /suscripciones/historial) y botón
/// "Renovar / Cambiar plan".
class AdminSuscripcionPage extends StatefulWidget {
  final bool embedded;
  const AdminSuscripcionPage({super.key, this.embedded = false});

  @override
  State<AdminSuscripcionPage> createState() => _AdminSuscripcionPageState();
}

class _AdminSuscripcionPageState extends State<AdminSuscripcionPage> {
  bool _cargando = true;
  bool _sesionExpirada = false;
  String _error = '';
  Map<String, dynamic>? _suscripcion;
  List<dynamic> _planes = const [];
  List<dynamic> _historial = const [];

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
        http.get(ApiClient.uri('/suscripciones/mi-suscripcion'), headers: ApiClient.authHeaders()),
        http.get(ApiClient.uri('/suscripciones/planes'), headers: ApiClient.authHeaders()),
        http.get(ApiClient.uri('/suscripciones/historial'), headers: ApiClient.authHeaders()),
      ]);
      final resSub = results[0];
      final resPlanes = results[1];
      final resHistorial = results[2];

      for (final res in results) {
        if (ApiClient.esErrorAuth(res)) {
          await ApiClient.manejarErrorAuth();
        }
      }

      // Planes: útil incluso si la suscripción falla por 404
      if (resPlanes.statusCode >= 200 && resPlanes.statusCode < 300) {
        final decoded = jsonDecode(resPlanes.body);
        _planes = decoded is List ? decoded : const [];
      } else {
        final msg = ApiClient.mensajeHttp(resPlanes, fallback: 'No se pudieron cargar los planes');
        // ignore: avoid_print
        print('[AdminSuscripcionPage] planes: $msg');
        throw Exception(msg);
      }

      if (resSub.statusCode >= 200 && resSub.statusCode < 300) {
        final decoded = jsonDecode(resSub.body);
        _suscripcion = decoded is Map<String, dynamic> ? decoded : null;
      } else if (resSub.statusCode == 404) {
        _suscripcion = null;
      } else {
        final msg = ApiClient.mensajeHttp(resSub, fallback: 'No se pudo cargar la suscripción');
        // ignore: avoid_print
        print('[AdminSuscripcionPage] mi-suscripcion: $msg');
        throw Exception(msg);
      }

      // Historial de pagos: si falla, no bloquea la pantalla
      if (resHistorial.statusCode >= 200 && resHistorial.statusCode < 300) {
        final decoded = jsonDecode(resHistorial.body);
        _historial = decoded is List ? decoded : const [];
      } else {
        _historial = const [];
      }

      if (!mounted) return;
      setState(() => _cargando = false);
    } on SesionExpiradaException {
      if (!mounted) return;
      setState(() {
        _sesionExpirada = true;
        _cargando = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[AdminSuscripcionPage] Error: $e');
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
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  String _fmtPrecio(dynamic v) {
    if (v == null) return 'Bs. 0.00';
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    return 'Bs. ${n.toStringAsFixed(2)}';
  }

  int? get _planActualId {
    final plan = _suscripcion?['plan'];
    if (plan is Map) return (plan['id'] as num?)?.toInt();
    return null;
  }

  int get _diasRestantes {
    final fin = _suscripcion?['fecha_fin'];
    if (fin == null) return 0;
    final fechaFin = DateTime.tryParse(fin.toString());
    if (fechaFin == null) return 0;
    final hoy = DateTime.now();
    return fechaFin.difference(hoy).inDays;
  }

  Future<void> _abrirModalPago(Map<String, dynamic> plan) async {
    final planId = (plan['id'] as num?)?.toInt();
    final nombre = (plan['nombre'] ?? 'Plan').toString();
    final precio = _fmtPrecio(plan['precio_mensual']);
    if (planId == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ModalPagoSimulado(planNombre: nombre, precioTexto: precio),
    );
    if (confirmado != true || !mounted) return;
    await _confirmarPago(planId);
  }

  Future<void> _confirmarPago(int planId) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    var loaderCerrado = false;
    void cerrarLoader() {
      if (!loaderCerrado && mounted) {
        loaderCerrado = true;
        Navigator.of(context).pop();
      }
    }

    try {
      final res = await http.post(
        ApiClient.uri('/suscripciones/confirmar-pago'),
        headers: ApiClient.jsonHeaders(),
        body: jsonEncode({'plan_id': planId, 'payment_status': 'success'}),
      );
      if (!mounted) return;
      cerrarLoader();
      if (ApiClient.esErrorAuth(res)) {
        await ApiClient.manejarErrorAuth();
      }
      if (!mounted) return;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = ApiClient.mensajeHttp(res, fallback: 'No se pudo confirmar el pago');
        // ignore: avoid_print
        print('[AdminSuscripcionPage] confirmar-pago: $msg');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago Exitoso'), backgroundColor: Colors.green),
      );
      await _cargar();
    } on SesionExpiradaException {
      cerrarLoader();
    } catch (e) {
      // ignore: avoid_print
      print('[AdminSuscripcionPage] Error confirmar pago: $e');
      cerrarLoader();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// [2.6] Selector rápido de planes para "Renovar / Cambiar plan".
  Future<void> _abrirSelectorPlanes() async {
    if (_planes.isEmpty) return;
    final planActualId = _planActualId;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Renovar / Cambiar plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Elige el plan para tu empresa', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            for (final p in _planes) ..._tilePlanSelector(ctx, (p as Map).cast<String, dynamic>(), planActualId),
          ],
        ),
      ),
    );
  }

  List<Widget> _tilePlanSelector(BuildContext ctx, Map<String, dynamic> plan, int? planActualId) {
    final id = (plan['id'] as num?)?.toInt();
    final esActual = id != null && id == planActualId;
    return [
      Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Icon(
            esActual ? Icons.check_circle : Icons.workspace_premium_outlined,
            color: esActual ? Colors.green : AppTheme.bronce,
          ),
          title: Text('${plan['nombre']}', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(_fmtPrecio(plan['precio_mensual'])),
          trailing: esActual
              ? const Chip(label: Text('Actual'), visualDensity: VisualDensity.compact)
              : const Icon(Icons.chevron_right),
          onTap: esActual
              ? null
              : () {
                  Navigator.of(ctx).pop();
                  _abrirModalPago(plan);
                },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Suscripción')),
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

    final planActual = _suscripcion?['plan'] as Map?;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cardPlanActual(planActual),
          const SizedBox(height: 20),
          _seccionHistorial(),
          const SizedBox(height: 20),
          const Text('Planes disponibles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_planes.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No hay planes disponibles.')))
          else
            ..._planes.map((p) {
              final plan = p as Map? ?? const {};
              final id = (plan['id'] as num?)?.toInt();
              final esActual = id != null && id == _planActualId;
              return _cardPlan(plan.cast<String, dynamic>(), esActual: esActual);
            }),
        ],
      ),
    );
  }

  // ---------------- Plan actual ----------------
  Widget _cardPlanActual(Map? plan) {
    if (plan == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Plan actual', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('No tienes una suscripción activa.'),
            ],
          ),
        ),
      );
    }
    final nombre = (plan['nombre'] ?? '—').toString();
    final precio = _fmtPrecio(plan['precio_mensual']);
    final inicio = _fmtFecha(_suscripcion?['fecha_inicio']);
    final vence = _fmtFecha(_suscripcion?['fecha_fin']);
    final estado = (_suscripcion?['estado'] ?? '').toString();
    final dias = _diasRestantes;
    final activa = estado.isEmpty || estado == 'activo';

    return Card(
      color: AppTheme.negro,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: AppTheme.amarilloMarca),
                const SizedBox(width: 8),
                const Text('Plan actual', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: activa ? Colors.green.withValues(alpha: 0.18) : Colors.red.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activa ? 'Activo' : estado,
                    style: TextStyle(
                      color: activa ? Colors.green.shade300 : Colors.red.shade300,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text('$precio / mes', style: const TextStyle(color: AppTheme.amarilloMarca, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _datoFecha('Inicio', inicio),
                ),
                Expanded(child: _datoFecha('Vence', vence)),
                Expanded(child: _datoFecha('Días restantes', dias > 0 ? '$dias' : '—')),
              ],
            ),
            if (dias >= 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (dias / 30).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  color: dias <= 5 ? Colors.red.shade300 : AppTheme.amarilloMarca,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _abrirSelectorPlanes,
                icon: const Icon(Icons.autorenew),
                label: const Text('Renovar / Cambiar plan'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.amarilloMarca,
                  foregroundColor: AppTheme.negro,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoFecha(String etiqueta, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  // ---------------- Historial de pagos ----------------
  Widget _seccionHistorial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Historial de pagos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (_historial.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aún no hay pagos registrados.'),
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                for (var i = 0; i < _historial.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 12, endIndent: 12),
                  _tilePago((_historial[i] as Map).cast<String, dynamic>()),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _tilePago(Map<String, dynamic> pago) {
    final nombre = (pago['plan_nombre'] ?? 'Plan').toString();
    final monto = _fmtPrecio(pago['precio_mensual']);
    final inicio = _fmtFecha(pago['fecha_inicio']);
    final fin = _fmtFecha(pago['fecha_fin']);
    final estado = (pago['estado'] ?? '').toString();
    final activo = estado == 'activo';
    return ListTile(
      leading: Icon(
        activo ? Icons.check_circle : Icons.history,
        color: activo ? Colors.green : Colors.grey,
      ),
      title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$monto · $inicio → $fin'),
      trailing: Chip(
        label: Text(activo ? 'Vigente' : 'Finalizado'),
        visualDensity: VisualDensity.compact,
        backgroundColor: activo ? Colors.green.withValues(alpha: 0.12) : Colors.grey.shade200,
        labelStyle: TextStyle(
          color: activo ? Colors.green.shade800 : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  // ---------------- Planes disponibles ----------------
  Widget _cardPlan(Map<String, dynamic> plan, {required bool esActual}) {
    final nombre = (plan['nombre'] ?? 'Plan').toString();
    final precio = _fmtPrecio(plan['precio_mensual']);
    final maxSuc = plan['max_sucursales'] ?? '-';
    final ia = plan['permite_ia'] == true ? 'Sí' : 'No';
    final desc = (plan['descripcion'] ?? '').toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                Text(precio, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            ],
            const SizedBox(height: 6),
            Text('Sucursales máx.: $maxSuc · IA: $ia', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: esActual
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Plan actual'),
                    )
                  : FilledButton(
                      onPressed: () => _abrirModalPago(plan),
                      child: const Text('Cambiar a este Plan'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalPagoSimulado extends StatefulWidget {
  final String planNombre;
  final String precioTexto;
  const _ModalPagoSimulado({required this.planNombre, required this.precioTexto});

  @override
  State<_ModalPagoSimulado> createState() => _ModalPagoSimuladoState();
}

class _ModalPagoSimuladoState extends State<_ModalPagoSimulado> {
  final _formKey = GlobalKey<FormState>();
  final _titular = TextEditingController();
  final _numero = TextEditingController();
  final _fecha = TextEditingController();
  final _cvc = TextEditingController();

  @override
  void dispose() {
    _titular.dispose();
    _numero.dispose();
    _fecha.dispose();
    _cvc.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pago simulado · ${widget.planNombre}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monto: ${widget.precioTexto}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titular,
                decoration: const InputDecoration(labelText: 'Titular', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el titular' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _numero,
                decoration: const InputDecoration(labelText: 'Número de tarjeta', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final d = (v ?? '').replaceAll(RegExp(r'\s+'), '');
                  if (d.length < 12) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fecha,
                      decoration: const InputDecoration(labelText: 'Fecha (MM/AA)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.datetime,
                      validator: (v) => (v == null || v.trim().length < 4) ? 'Fecha inválida' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _cvc,
                      decoration: const InputDecoration(labelText: 'CVC', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: (v) => (v == null || v.trim().length < 3) ? 'CVC inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Simulación: no se realiza un cobro real.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(onPressed: _confirmar, child: const Text('Confirmar pago')),
      ],
    );
  }
}
