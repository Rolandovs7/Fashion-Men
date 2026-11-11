import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/pedidos_service.dart';
import '../services/auth_service.dart';
import '../services/tipos_pago_service.dart';
import '../services/stripe_service.dart';
import '../core/sesion.dart';
import '../core/theme.dart';
import 'login_page.dart';
import 'pago_qr_page.dart';

class MisPedidosPage extends StatefulWidget {
  final bool embedded;
  const MisPedidosPage({super.key, this.embedded = false});

  @override
  State<MisPedidosPage> createState() => _MisPedidosPageState();
}

class _MisPedidosPageState extends State<MisPedidosPage> {
  final pedidosService = PedidosService();
  final tiposPagoService = TiposPagoService();
  final stripeService = StripeService();

  List<Pedido> pedidos = [];
  List<TipoPago> tiposPago = [];
  bool cargando = true;
  String error = '';
  String mensaje = '';

  bool _stripeListo = false;
  int? _pedidoIdProcesandoStripe;

  /// [Fix 1.3] true cuando un pago falló por 401 real: se muestra el mensaje
  /// inline "Tu sesión expiró..." con botón, sin cerrar la app.
  bool _sesionExpirada = false;

  final etiquetas = const {
    'pendiente': 'Pendiente',
    'pagado': 'Pagado',
    'procesando': 'Procesando',
    'enviado': 'Enviado',
    'entregado': 'Entregado',
    'cancelado': 'Cancelado',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
    tiposPagoService.listar().then((tipos) {
      if (mounted) setState(() => tiposPago = tipos);
    });
  }

  Future<void> _cargar() async {
    if ((AuthService.instance.token ?? '').trim().isEmpty) {
      // Sin token: cierre completo (flag anti-bucle) y Login una sola vez.
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    setState(() {
      cargando = true;
      error = '';
      _sesionExpirada = false;
    });

    try {
      final resultado = await pedidosService.listarMisPedidos();
      if (!mounted) return;
      setState(() {
        pedidos = resultado;
        cargando = false;
      });
    } on SesionExpiradaException {
      if (!mounted) return;
      setState(() {
        cargando = false;
        error = '';
      });
      // ApiClient ya redirige globalmente al Login.
    } catch (e) {
      // ignore: avoid_print
      print('[MisPedidosPage] Error: $e');
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        cargando = false;
      });
    }
  }

  Future<void> _cancelar(Pedido pedido) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Cancelar el pedido #${pedido.id}?'),
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
      await pedidosService.cancelar(pedido.id);
      setState(() => mensaje = 'Pedido #${pedido.id} cancelado.');
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Método por defecto para el pago manual ([Fix 1.4]): prefiere "efectivo".
  String _metodoPagoManual() {
    for (final t in tiposPago) {
      if (t.nombre.trim().toLowerCase() == 'efectivo') return t.nombre;
    }
    return tiposPago.isNotEmpty ? tiposPago.first.nombre : 'efectivo';
  }

  /// [Fix 1.4] Registrar pago manual: sin selector de métodos
  /// (tarjeta/QR/manual); se muestra directamente el botón "Confirmar pago".
  /// [Fix 1.3] Ante un 401 real no se redirige al Login: mensaje inline con
  /// botón. Los 400/402/403/422 muestran el mensaje real del backend.
  Future<void> _pagar(Pedido pedido) async {
    final metodo = _metodoPagoManual();
    final referenciaController = TextEditingController();

    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pagar pedido #${pedido.id}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total: Bs ${pedido.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Text(
              'Método: $metodo',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: referenciaController,
              decoration: const InputDecoration(
                labelText: 'Referencia (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Confirmar pago de Bs ${pedido.total.toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
      ),
    );

    final referencia = referenciaController.text.trim();
    referenciaController.dispose();

    if (confirmar != true) return;

    try {
      // [Fix 1.3] Sin redirección automática: el 401 se maneja inline.
      await ApiClient.sinRedireccionAutomatica(
        () => pedidosService.pagar(
          pedidoId: pedido.id,
          metodo: metodo,
          monto: pedido.total,
          referencia: referencia.isEmpty ? null : referencia,
        ),
      );
      setState(
        () =>
            mensaje = 'Pago del pedido #${pedido.id} procesado correctamente.',
      );
      _cargar();
    } on SesionExpiradaException {
      _marcarSesionExpirada();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// [Fix 1.3] Marca sesión expirada para mostrar el mensaje inline.
  void _marcarSesionExpirada() {
    if (!mounted) return;
    setState(() {
      _sesionExpirada = true;
      error = '';
      mensaje = '';
    });
  }

  /// [Fix 1.3] Botón inline del mensaje de sesión expirada.
  Future<void> _irALogin() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _pagarConStripe(Pedido pedido) async {
    setState(() {
      _pedidoIdProcesandoStripe = pedido.id;
      error = '';
      mensaje = '';
      _sesionExpirada = false;
    });

    try {
      var estado = '';
      // [Fix 1.3] Sin redirección automática ante 401: mensaje inline.
      await ApiClient.sinRedireccionAutomatica(() async {
        if (!_stripeListo) {
          final config = await stripeService.obtenerConfig();
          Stripe.publishableKey = config.publishableKey;
          await Stripe.instance.applySettings();
          _stripeListo = true;
        }

        final intent = await stripeService.crearIntent(pedido.id, moneda: 'usd');

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: intent.clientSecret,
            merchantDisplayName: 'MenStyle',
          ),
        );

        await Stripe.instance.presentPaymentSheet();

        estado = await stripeService.confirmarPago(intent.paymentIntentId);
      });

      if (!mounted) return;
      setState(() {
        _pedidoIdProcesandoStripe = null;
        mensaje = estado == 'succeeded'
            ? 'Pago con tarjeta exitoso para el pedido #${pedido.id}.'
            : 'Pago en estado: $estado';
      });
      _cargar();
    } on SesionExpiradaException {
      if (!mounted) return;
      setState(() => _pedidoIdProcesandoStripe = null);
      _marcarSesionExpirada();
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() {
        _pedidoIdProcesandoStripe = null;
        error = e.error.localizedMessage ?? 'El pago fue cancelado.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pedidoIdProcesandoStripe = null;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool _puedeCancelar(Pedido p) =>
      !['cancelado', 'entregado'].contains(p.estado);

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.amber.shade800;
      case 'pagado':
      case 'procesando':
        return Colors.blue.shade700;
      case 'enviado':
        return Colors.indigo;
      case 'entregado':
        return Colors.green.shade700;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// [Rediseño] Card de pedido: bordes redondeados, sombra suave,
  /// estado en chip de color, total destacado y acciones alineadas.
  Widget _tarjetaPedido(Pedido pedido) {
    final color = _colorEstado(pedido.estado);
    final pendiente = pedido.estado == 'pendiente';
    final puedeCancelar = _puedeCancelar(pedido);

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${pedido.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.negro,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pedido.fechaPedido.substring(0, 10),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                    etiquetas[pedido.estado] ?? pedido.estado,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.fondoClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Bs ${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.negro,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _verComprobante(pedido),
                    icon: const Icon(Icons.receipt_long_outlined, size: 17),
                    label: const Text('Ver comprobante'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.negro,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (pendiente)
                    FilledButton.icon(
                      onPressed: _pedidoIdProcesandoStripe == pedido.id
                          ? null
                          : () => _pagarConStripe(pedido),
                      icon: _pedidoIdProcesandoStripe == pedido.id
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.credit_card, size: 17),
                      label: Text(
                        _pedidoIdProcesandoStripe == pedido.id
                            ? 'Procesando...'
                            : 'Pagar',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.negro,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (puedeCancelar)
                    TextButton.icon(
                      onPressed: () => _cancelar(pedido),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Cancelar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            if (pendiente) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _pagarConQr(pedido),
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text('Pagar con QR'),
                  ),
                  TextButton(
                    onPressed: () => _pagar(pedido),
                    child: const Text('Pago manual'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// CU20 - Nota de venta del pedido para el cliente.
  Future<void> _verComprobante(Pedido pedido) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: AppTheme.bronce),
            const SizedBox(width: 8),
            const Text(
              'Comprobante',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pedido #${pedido.id}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '${pedido.fechaPedido.substring(0, 10)} · ${etiquetas[pedido.estado] ?? pedido.estado}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const Divider(height: 22),
              for (final d in pedido.detalles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Variante #${d.varianteId} × ${d.cantidad}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        'Bs ${d.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 22),
              Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    'Bs ${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoPedidos,
      appBar: widget.embedded ? null : AppBar(title: const Text('Mis pedidos')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_sesionExpirada) _bannerSesionExpirada(),
                  if (mensaje.isNotEmpty) _banner(mensaje, Colors.green),
                  if (error.isNotEmpty) _banner(error, Colors.red),
                  if (!cargando && pedidos.isEmpty && error.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'Aún no tienes pedidos.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ...pedidos.map((pedido) => _tarjetaPedido(pedido)),
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

  /// [Fix 1.3] Mensaje inline de sesión expirada con botón para volver al
  /// Login. No cierra la app ni redirige automáticamente.
  Widget _bannerSesionExpirada() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.red.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tu sesión expiró. Iniciá sesión de nuevo',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _irALogin,
          icon: const Icon(Icons.login),
          label: const Text('Iniciar sesión de nuevo'),
        ),
      ],
    ),
  );

  Future<void> _pagarConQr(Pedido pedido) async {
    // Abrir la pantalla de QR y esperar el resultado
    final referencia = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PagoQrPage(
          pedidoId: pedido.id,
          monto: pedido.total,
        ),
      ),
    );

    if (referencia == null) return;

    // El usuario confirmó que ya pagó. Registrar el pago manualmente.
    try {
      // [Fix 1.3] Sin redirección automática ante 401: mensaje inline.
      await ApiClient.sinRedireccionAutomatica(
        () => pedidosService.pagar(
          pedidoId: pedido.id,
          metodo: 'qr',
          monto: pedido.total,
          referencia: referencia,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago por QR registrado. Esperando confirmación.'),
        ),
      );
      await _cargar();
    } on SesionExpiradaException {
      _marcarSesionExpirada();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

}
