import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

// ============================================================
// CU08 - Gestión de Tipo de Prenda
// RF: pendiente de confirmar según matriz oficial (relacionado con
// RF04 - Gestionar productos de ropa / RF05 - clasificación del producto)
// Consume los endpoints existentes en api/routes/garment_types.py,
// montados en FastAPI bajo el prefijo real /api/tipos-prenda
// (mismo backend que ya usa Angular en pages/admin-catalogo).
// ============================================================
class TipoPrenda {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  TipoPrenda({required this.id, required this.nombre, this.descripcion, required this.activo});

  factory TipoPrenda.fromJson(Map<String, dynamic> json) => TipoPrenda(
        id: json['id'],
        nombre: json['nombre'],
        descripcion: json['descripcion'],
        activo: json['activo'] ?? true,
      );
}

class GarmentTypesService {
  static final GarmentTypesService instance = GarmentTypesService._internal();
  factory GarmentTypesService() => instance;
  GarmentTypesService._internal();

  // CU08 / GET /api/tipos-prenda - lista los tipos de prenda
  Future<List<TipoPrenda>> listar({bool soloActivos = false}) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/tipos-prenda?solo_activos=$soloActivos'),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => TipoPrenda.fromJson(e)).toList();
  }

  // CU08 / POST /api/tipos-prenda - crea un tipo de prenda (requiere admin)
  Future<TipoPrenda> crear(String nombre, String? descripcion) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/tipos-prenda'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    _verificar(response);
    return TipoPrenda.fromJson(jsonDecode(response.body));
  }

  // CU08 / PUT /api/tipos-prenda/{id} - edita un tipo de prenda (requiere admin)
  Future<TipoPrenda> actualizar(int id, {String? nombre, String? descripcion}) async {
    final body = <String, dynamic>{};
    if (nombre != null) body['nombre'] = nombre;
    if (descripcion != null) body['descripcion'] = descripcion;

    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/tipos-prenda/$id'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode(body),
    );
    _verificar(response);
    return TipoPrenda.fromJson(jsonDecode(response.body));
  }

  // CU08 / DELETE /api/tipos-prenda/{id} - desactiva (soft delete, requiere admin)
  Future<void> eliminar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/tipos-prenda/$id'),
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
    return 'No se pudo completar la operación de tipos de prenda';
  }
}
