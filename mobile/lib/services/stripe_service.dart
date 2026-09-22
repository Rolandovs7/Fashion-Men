import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';

class StripeConfigInfo {
  final String publishableKey;
  final String modo;

  StripeConfigInfo({required this.publishableKey, required this.modo});

  factory StripeConfigInfo.fromJson(Map<String, dynamic> json) =>
      StripeConfigInfo(
        publishableKey: json['publishable_key'],
        modo: json['modo'],
      );
}

class StripeIntentInfo {
  final String clientSecret;
  final String paymentIntentId;
  final double monto;
  final String moneda;

  StripeIntentInfo({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.monto,
    required this.moneda,
  });

  factory StripeIntentInfo.fromJson(Map<String, dynamic> json) =>
      StripeIntentInfo(
        clientSecret: json['client_secret'],
        paymentIntentId: json['payment_intent_id'],
        monto: (json['monto'] as num).toDouble(),
        moneda: json['moneda'],
      );
}

/// Habla con los endpoints de Stripe de tu backend (RF19).
class StripeService {
  static final StripeService instance = StripeService._internal();
  factory StripeService() => instance;
  StripeService._internal();

  Future<StripeConfigInfo> obtenerConfig() async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/pagos/stripe/config'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    return StripeConfigInfo.fromJson(jsonDecode(response.body));
  }

  Future<StripeIntentInfo> crearIntent(
    int pedidoId, {
    String moneda = 'usd',
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/pagos/stripe/intent'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'pedido_id': pedidoId, 'moneda': moneda}),
    );
    _verificar(response);
    return StripeIntentInfo.fromJson(jsonDecode(response.body));
  }

  Future<String> confirmarPago(String paymentIntentId) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/pagos/stripe/confirm'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'payment_intent_id': paymentIntentId}),
    );
    _verificar(response);
    final data = jsonDecode(response.body);
    return data['estado'] as String;
  }

  void _verificar(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extraerError(response.body));
    }
  }

  String _extraerError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {}
    return 'No se pudo procesar el pago con Stripe';
  }
}
