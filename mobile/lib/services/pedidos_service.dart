import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_client.dart';

class PedidosService {
  static final PedidosService instance = PedidosService._internal();
  factory PedidosService() => instance;
  PedidosService._internal();

  Future<List<Pedido>> listarMisPedidos() async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/pedidos'),
      headers: ApiClient.authHeaders(),
    );
    await _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Pedido.fromJson(e)).toList();
  }

  Future<Pedido> crearDesdeCarrito(int sucursalId) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/pedidos'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'sucursal_id': sucursalId}),
    );
    await _verificar(response);
    return Pedido.fromJson(jsonDecode(response.body));
  }

  Future<Pedido> cancelar(int pedidoId) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/pedidos/$pedidoId/cancelar'),
      headers: ApiClient.authHeaders(),
    );
    await _verificar(response);
    return Pedido.fromJson(jsonDecode(response.body));
  }

  Future<void> pagar({
    required int pedidoId,
    required String metodo,
    required double monto,
    String? referencia,
  }) async {
    // El JWT viaja siempre en Authorization. Se construye en el momento de
    // la petición (no al crear el servicio) para usar el token vigente.
    final headers = ApiClient.jsonHeaders();
    if (!headers.containsKey('Authorization')) {
      throw Exception('No hay una sesión activa. Inicia sesión de nuevo.');
    }
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/pagos'),
      headers: headers,
      body: jsonEncode({
        'pedido_id': pedidoId,
        'metodo': metodo,
        'monto': monto,
        'referencia': referencia,
      }),
    );
    await _verificar(response);
  }

  // ----- Administración -----
  Future<List<Pedido>> listarTodos({String? estado}) async {
    final query = estado != null ? '?estado=$estado' : '';
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/pedidos/admin/todos$query'),
      headers: ApiClient.authHeaders(),
    );
    await _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Pedido.fromJson(e)).toList();
  }

  Future<Pedido> cambiarEstado(int pedidoId, String nuevoEstado) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/pedidos/$pedidoId/estado'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'nuevo_estado': nuevoEstado}),
    );
    await _verificar(response);
    return Pedido.fromJson(jsonDecode(response.body));
  }

  Future<Pedido> crearVentaPresencial({
    required int usuarioId,
    required int sucursalId,
    required String metodoPago,
    required List<Map<String, int>> items,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/pedidos/venta-presencial'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'usuario_id': usuarioId,
        'sucursal_id': sucursalId,
        'metodo_pago': metodoPago,
        'items': items,
      }),
    );
    await _verificar(response);
    return Pedido.fromJson(jsonDecode(response.body));
  }

  Future<void> _verificar(http.Response response) async {
    if (ApiClient.esErrorAuth(response)) {
      await ApiClient.manejarErrorAuth();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = _extraerError(response);
      // ignore: avoid_print
      print('[PedidosService] HTTP ${response.statusCode}: $msg');
      throw Exception(msg);
    }
  }

  /// Extrae el mensaje real del backend. Cubre `detail` como texto
  /// (400/403/409) y como lista de validación (422).
  String _extraerError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        final detail = data['detail'] ?? data['message'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
        if (detail is List) {
          final mensajes = detail
              .map((e) => e is Map ? (e['msg'] ?? e.toString()) : e.toString())
              .where((m) => m.trim().isNotEmpty)
              .join(', ');
          if (mensajes.isNotEmpty) return mensajes;
        }
      }
    } catch (_) {
      // El cuerpo no era JSON.
    }
    final body = response.body.trim();
    if (body.isNotEmpty && body.length < 180) return body;
    return 'No se pudo completar la operación (HTTP ${response.statusCode})';
  }
}
