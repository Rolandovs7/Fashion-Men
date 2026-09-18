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
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Pedido.fromJson(e)).toList();
  }

  Future<Pedido> crearDesdeCarrito(int sucursalId) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/pedidos'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'sucursal_id': sucursalId}),
    );
    _verificar(response);
    return Pedido.fromJson(jsonDecode(response.body));
  }

  Future<Pedido> cancelar(int pedidoId) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/pedidos/$pedidoId/cancelar'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    return Pedido.fromJson(jsonDecode(response.body));
  }

  Future<void> pagar({
    required int pedidoId,
    required String metodo,
    required double monto,
    String? referencia,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/pagos'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'pedido_id': pedidoId,
        'metodo': metodo,
        'monto': monto,
        'referencia': referencia,
      }),
    );
    _verificar(response);
  }

  // ----- Administración -----
  Future<List<Pedido>> listarTodos({String? estado}) async {
    final query = estado != null ? '?estado=$estado' : '';
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/pedidos/admin/todos$query'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Pedido.fromJson(e)).toList();
  }

  Future<Pedido> cambiarEstado(int pedidoId, String nuevoEstado) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/pedidos/$pedidoId/estado'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'nuevo_estado': nuevoEstado}),
    );
    _verificar(response);
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
    _verificar(response);
    return Pedido.fromJson(jsonDecode(response.body));
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
    return 'No se pudo completar la operación del pedido';
  }
}
