import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

// ============================================================
// CU09 - Gestión de Descuentos
// RF: pendiente de confirmar según matriz oficial (no existe un
// RF explícito de "promociones/descuentos" en el documento de 25 RF)
// Consume los endpoints existentes en api/routes/discounts.py,
// montados en FastAPI bajo el prefijo real /api/descuentos
// (mismo backend que ya usa Angular en pages/admin-catalogo).
// ============================================================
class Descuento {
  final int id;
  final String nombre;
  final double porcentaje;
  final String? fechaInicio;
  final String? fechaFin;
  final bool activo;

  Descuento({
    required this.id,
    required this.nombre,
    required this.porcentaje,
    this.fechaInicio,
    this.fechaFin,
    required this.activo,
  });

  factory Descuento.fromJson(Map<String, dynamic> json) => Descuento(
        id: json['id'],
        nombre: json['nombre'],
        porcentaje: (json['porcentaje'] as num).toDouble(),
        fechaInicio: json['fecha_inicio'],
        fechaFin: json['fecha_fin'],
        activo: json['activo'] ?? true,
      );
}

class DiscountsService {
  static final DiscountsService instance = DiscountsService._internal();
  factory DiscountsService() => instance;
  DiscountsService._internal();

  // CU09 / GET /api/descuentos - lista los descuentos/promociones
  Future<List<Descuento>> listar({bool soloActivos = false}) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/descuentos?solo_activos=$soloActivos'),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Descuento.fromJson(e)).toList();
  }

  // CU09 / POST /api/descuentos - crea un descuento (requiere admin)
  // porcentaje debe estar entre 0 (exclusivo) y 100 (inclusivo);
  // fechas en formato ISO (yyyy-MM-dd), ambas opcionales.
  Future<Descuento> crear({
    required String nombre,
    required double porcentaje,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/descuentos'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'porcentaje': porcentaje,
        'fecha_inicio': fechaInicio,
        'fecha_fin': fechaFin,
      }),
    );
    _verificar(response);
    return Descuento.fromJson(jsonDecode(response.body));
  }

  // CU09 / PUT /api/descuentos/{id} - edita un descuento (requiere admin)
  Future<Descuento> actualizar(
    int id, {
    String? nombre,
    double? porcentaje,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final body = <String, dynamic>{};
    if (nombre != null) body['nombre'] = nombre;
    if (porcentaje != null) body['porcentaje'] = porcentaje;
    if (fechaInicio != null) body['fecha_inicio'] = fechaInicio;
    if (fechaFin != null) body['fecha_fin'] = fechaFin;

    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/descuentos/$id'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode(body),
    );
    _verificar(response);
    return Descuento.fromJson(jsonDecode(response.body));
  }

  // CU09 / DELETE /api/descuentos/{id} - desactiva (soft delete, requiere admin)
  Future<void> eliminar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/descuentos/$id'),
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
    return 'No se pudo completar la operación de descuentos';
  }
}
