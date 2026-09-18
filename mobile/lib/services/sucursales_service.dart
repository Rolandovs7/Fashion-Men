import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_client.dart';

class SucursalesService {
  static final SucursalesService instance = SucursalesService._internal();
  factory SucursalesService() => instance;
  SucursalesService._internal();

  Future<List<Sucursal>> listar({bool soloActivos = true}) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/sucursales?solo_activos=$soloActivos'),
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las sucursales');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((e) => Sucursal.fromJson(e)).toList();
  }

  Future<Sucursal> crear({
    required String nombre,
    required String direccion,
    required String ciudad,
    String? telefono,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/sucursales'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'direccion': direccion,
        'ciudad': ciudad,
        'telefono': telefono,
      }),
    );
    _verificar(response);
    return Sucursal.fromJson(jsonDecode(response.body));
  }

  Future<void> eliminar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/sucursales/$id'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
  }

  Future<Sucursal> actualizar({
    required int id,
    required String nombre,
    required String direccion,
    required String ciudad,
    String? telefono,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/sucursales/$id'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'direccion': direccion,
        'ciudad': ciudad,
        'telefono': telefono,
      }),
    );
    _verificar(response);
    return Sucursal.fromJson(jsonDecode(response.body));
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
    return 'No se pudo completar la operación de sucursales';
  }
}
