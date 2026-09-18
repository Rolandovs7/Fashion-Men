import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

// ============================================================
// CU10 - Gestión de Marcas
// RF: pendiente de confirmar según matriz oficial (relacionado con
// RF04 - Gestionar productos de ropa)
// Consume los endpoints existentes en api/routes/brands.py,
// montados en FastAPI bajo el prefijo real /api/marcas
// (mismo backend que ya usa Angular en pages/admin-catalogo).
// ============================================================
class Marca {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  Marca({required this.id, required this.nombre, this.descripcion, required this.activo});

  factory Marca.fromJson(Map<String, dynamic> json) => Marca(
        id: json['id'],
        nombre: json['nombre'],
        descripcion: json['descripcion'],
        activo: json['activo'] ?? true,
      );
}

class BrandsService {
  static final BrandsService instance = BrandsService._internal();
  factory BrandsService() => instance;
  BrandsService._internal();

  // CU10 / GET /api/marcas - lista las marcas
  Future<List<Marca>> listar({bool soloActivos = false}) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/marcas?solo_activos=$soloActivos'),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Marca.fromJson(e)).toList();
  }

  // CU10 / POST /api/marcas - crea una marca (requiere admin)
  Future<Marca> crear(String nombre, String? descripcion) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/marcas'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    _verificar(response);
    return Marca.fromJson(jsonDecode(response.body));
  }

  // CU10 / PUT /api/marcas/{id} - edita una marca (requiere admin)
  Future<Marca> actualizar(int id, {String? nombre, String? descripcion}) async {
    final body = <String, dynamic>{};
    if (nombre != null) body['nombre'] = nombre;
    if (descripcion != null) body['descripcion'] = descripcion;

    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/marcas/$id'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode(body),
    );
    _verificar(response);
    return Marca.fromJson(jsonDecode(response.body));
  }

  // CU10 / DELETE /api/marcas/{id} - desactiva (soft delete, requiere admin)
  Future<void> eliminar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/marcas/$id'),
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
    return 'No se pudo completar la operación de marcas';
  }
}
