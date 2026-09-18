import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_client.dart';

class CarritoService {
  static final CarritoService instance = CarritoService._internal();
  factory CarritoService() => instance;
  CarritoService._internal();

  Future<Carrito> obtener() async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/carrito'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    return Carrito.fromJson(jsonDecode(response.body));
  }

  Future<Carrito> agregarItem(int varianteId, int cantidad) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/carrito/items'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'variante_id': varianteId, 'cantidad': cantidad}),
    );
    _verificar(response);
    return Carrito.fromJson(jsonDecode(response.body));
  }

  Future<Carrito> actualizarItem(int detalleId, int cantidad) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/carrito/items/$detalleId'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'cantidad': cantidad}),
    );
    _verificar(response);
    return Carrito.fromJson(jsonDecode(response.body));
  }

  Future<Carrito> eliminarItem(int detalleId) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/carrito/items/$detalleId'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    return Carrito.fromJson(jsonDecode(response.body));
  }

  Future<Carrito> vaciar() async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/carrito'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    return Carrito.fromJson(jsonDecode(response.body));
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
    return 'No se pudo completar la operación del carrito';
  }
}
