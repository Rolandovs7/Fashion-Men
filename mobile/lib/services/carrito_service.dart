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
    if (ApiClient.esErrorAuth(response)) {
      await ApiClient.manejarErrorAuth();
    }
    // Cliente sin carrito aún: devolver vacío en lugar de romper la UI.
    if (response.statusCode == 404) {
      final uid = (jsonDecodeSafeUserId());
      return Carrito(id: 0, usuarioId: uid, detalles: const []);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String mensaje = 'Error en la operación del carrito';
      try {
        final data = jsonDecode(response.body);
        if (data['detail'] != null) mensaje = data['detail'].toString();
      } catch (_) {}
      // Algunos backends devuelven 500 cuando no existe carrito; degradar a vacío.
      if (response.statusCode == 500 &&
          (mensaje.toLowerCase().contains('carrito') || response.body.contains('carrito'))) {
        final uid = (jsonDecodeSafeUserId());
        return Carrito(id: 0, usuarioId: uid, detalles: const []);
      }
      // ignore: avoid_print
      print('[CarritoService] HTTP ${response.statusCode}: $mensaje');
      throw Exception(mensaje);
    }
    return Carrito.fromJson(jsonDecode(response.body));
  }

  int jsonDecodeSafeUserId() => 0;

  Future<Carrito> agregarItem(int varianteId, int cantidad) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/carrito/items'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'variante_id': varianteId, 'cantidad': cantidad}),
    );
    await _verificar(response);
    return Carrito.fromJson(jsonDecode(response.body));
  }

  Future<Carrito> actualizarItem(int detalleId, int cantidad) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/carrito/items/$detalleId'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'cantidad': cantidad}),
    );
    await _verificar(response);
    return Carrito.fromJson(jsonDecode(response.body));
  }

  Future<Carrito> eliminarItem(int detalleId) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/carrito/items/$detalleId'),
      headers: ApiClient.authHeaders(),
    );
    await _verificar(response);
    return Carrito.fromJson(jsonDecode(response.body));
  }

  Future<Carrito> vaciar() async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/carrito'),
      headers: ApiClient.authHeaders(),
    );
    await _verificar(response);
    return Carrito.fromJson(jsonDecode(response.body));
  }

  Future<void> _verificar(http.Response response) async {
    if (ApiClient.esErrorAuth(response)) {
      await ApiClient.manejarErrorAuth();
    }
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
