import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_client.dart';

class ProveedoresService {
  static final ProveedoresService instance = ProveedoresService._internal();
  factory ProveedoresService() => instance;
  ProveedoresService._internal();

  Future<List<Proveedor>> listar({bool soloActivos = false}) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/proveedores?solo_activos=$soloActivos'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Proveedor.fromJson(e)).toList();
  }

  Future<Proveedor> crear({
    required String nombre,
    String? contacto,
    String? telefono,
    String? email,
    String? direccion,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/proveedores'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'contacto': contacto,
        'telefono': telefono,
        'email': email,
        'direccion': direccion,
      }),
    );
    _verificar(response);
    return Proveedor.fromJson(jsonDecode(response.body));
  }

  Future<void> eliminar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/proveedores/$id'),
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
    return 'No se pudo completar la operación de proveedores';
  }
}
