import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

// ============================================================
// CU19 - Administrar Tipo de Pago
// RF18 - Permitir pagos en punto de caja
// RF19 - Integrar una pasarela de pago (sandbox propio)
// Espejo de tipos-pago.service.ts (Angular) y
// app/api/routes/payment_types.py (FastAPI). Reemplaza la lista
// fija ['efectivo','tarjeta','qr'] que antes tenían
// punto_venta_page.dart y mis_pedidos_page.dart.
// ============================================================
class TipoPago {
  final int id;
  final String nombre;
  final bool activo;

  TipoPago({required this.id, required this.nombre, required this.activo});

  factory TipoPago.fromJson(Map<String, dynamic> json) => TipoPago(
        id: json['id'],
        nombre: json['nombre'],
        activo: json['activo'] ?? true,
      );
}

class TiposPagoService {
  static final TiposPagoService instance = TiposPagoService._internal();
  factory TiposPagoService() => instance;
  TiposPagoService._internal();

  // CU19 / RF18-RF19 - Métodos de pago habilitados (para selects de checkout/caja)
  Future<List<TipoPago>> listar({bool soloActivos = true}) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/tipos-pago?solo_activos=$soloActivos'),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => TipoPago.fromJson(e)).toList();
  }

  Future<TipoPago> crear(String nombre) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/tipos-pago'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'nombre': nombre}),
    );
    _verificar(response);
    return TipoPago.fromJson(jsonDecode(response.body));
  }

  Future<void> eliminar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/tipos-pago/$id'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
  }

  void _verificar(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extraerError(response.body));
    }
  }

  String _extraerError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['detail'] != null) return data['detail'].toString();
    } catch (_) {}
    return 'No se pudo completar la operación de tipos de pago';
  }
}
