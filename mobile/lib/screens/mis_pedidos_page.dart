import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;

import '../models/models.dart';
import '../services/pedidos_service.dart';
import '../services/auth_service.dart';
import '../services/tipos_pago_service.dart';
import '../services/stripe_service.dart';
import '../core/theme.dart';

class MisPedidosPage extends StatefulWidget {
  const MisPedidosPage({super.key});

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
    if (AuthService.instance.token == null) {
      setState(() {
        cargando = false;
        error = 'Inicia sesión para ver tus pedidos.';
      });
      return;
    }

    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final resultado = await pedidosService.listarMisPedidos();
      setState(() {
        pedidos = resultado;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudieron cargar tus pedidos.';
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

  Future<void> _pagar(Pedido pedido) async {
    String metodo = tiposPago.isNotEmpty ? tiposPago.first.nombre : 'tarjeta';
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
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
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
              DropdownButtonFormField<String>(
                initialValue: metodo,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder(),
                ),
                items: tiposPago.isNotEmpty
                    ? tiposPago
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.nombre,
                              child: Text(t.nombre),
                            ),
                          )
                          .toList()
                    : [DropdownMenuItem(value: metodo, child: Text(metodo))],
                onChanged: (v) => setModalState(() => metodo = v ?? metodo),
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
      ),
    );

    if (confirmar != true) return;

    try {
      await pedidosService.pagar(
        pedidoId: pedido.id,
        metodo: metodo,
        monto: pedido.total,
        referencia: referenciaController.text.trim().isEmpty
            ? null
            : referenciaController.text.trim(),
      );
      setState(
        () =>
            mensaje = 'Pago del pedido #${pedido.id} procesado correctamente.',
      );
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _pagarConStripe(Pedido pedido) async {
    setState(() {
      _pedidoIdProcesandoStripe = pedido.id;
      error = '';
      mensaje = '';
    });

    try {
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

      final estado = await stripeService.confirmarPago(intent.paymentIntentId);

      if (!mounted) return;
      setState(() {
        _pedidoIdProcesandoStripe = null;
        mensaje = estado == 'succeeded'
            ? 'Pago con tarjeta exitoso para el pedido #${pedido.id}.'
            : 'Pago en estado: $estado';
      });
      _cargar();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoPedidos,
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                  ...pedidos.map(
                    (pedido) => Card(
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
                                  'Pedido #${pedido.id}',
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
                                    color: _colorEstado(pedido.estado)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    etiquetas[pedido.estado] ?? pedido.estado,
                                    style: TextStyle(
                                      color: _colorEstado(pedido.estado),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pedido.fechaPedido.substring(0, 10),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const Divider(height: 20),
                            Text(
                              'Total: Bs ${pedido.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (pedido.estado == 'pendiente') ...[
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: FilledButton.icon(
                                  onPressed:
                                      _pedidoIdProcesandoStripe == pedido.id
                                      ? null
                                      : () => _pagarConStripe(pedido),
                                  icon: _pedidoIdProcesandoStripe == pedido.id
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.credit_card),
                                  label: Text(
                                    _pedidoIdProcesandoStripe == pedido.id
                                        ? 'Procesando...'
                                        : 'Pagar con tarjeta',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (pedido.estado == 'pendiente')
                                  TextButton(
                                    onPressed: () => _pagar(pedido),
                                    child: const Text('Registrar pago manual'),
                                  ),
                                if (_puedeCancelar(pedido))
                                  TextButton(
                                    onPressed: () => _cancelar(pedido),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                              ],
                            ),
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
