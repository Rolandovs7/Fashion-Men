// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU19 - Integrar pasarela de pago
// RF: RF19 - Pagos electronicos (QR)
// CAPA: Frontend Flutter
// ============================================================
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PagoQrPage extends StatelessWidget {
  final int pedidoId;
  final double monto;

  const PagoQrPage({
    super.key,
    required this.pedidoId,
    required this.monto,
  });

  @override
  Widget build(BuildContext context) {
    // El QR contiene: identificador del sistema + pedido + monto + timestamp
    final qrData =
        'MenStyle|PAGO|$pedidoId|${monto.toStringAsFixed(2)}|${DateTime.now().millisecondsSinceEpoch}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Pago con QR - Pedido #$pedidoId'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Escanea este código QR para pagar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Total: Bs ${monto.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pedido #$pedidoId',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Ya realicé el pago'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                onPressed: () {
                  final referencia =
                      'QR-${DateTime.now().millisecondsSinceEpoch}';
                  Navigator.pop(context, referencia);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
