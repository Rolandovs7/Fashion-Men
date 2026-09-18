import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

// ============================================================
// CU15 - Administrar Inventario
// RF20 - Actualizar automáticamente el inventario tras una venta
// RF21 - Controlar las existencias por sucursal
// RF22 - Registrar movimientos de inventario
// Espejo exacto de inventario.service.ts (Angular) y
// app/api/routes/inventory.py (FastAPI). Mismos endpoints,
// mismas validaciones (ya aplicadas del lado del backend).
// ============================================================
class Inventario {
  final int id;
  final int varianteId;
  final int sucursalId;
  final int cantidad;
  final int cantidadReservada;

  Inventario({
    required this.id,
    required this.varianteId,
    required this.sucursalId,
    required this.cantidad,
    required this.cantidadReservada,
  });

  int get disponible => cantidad - cantidadReservada;

  factory Inventario.fromJson(Map<String, dynamic> json) => Inventario(
        id: json['id'],
        varianteId: json['variante_id'],
        sucursalId: json['sucursal_id'],
        cantidad: json['cantidad'],
        cantidadReservada: json['cantidad_reservada'],
      );
}

class InventarioService {
  static final InventarioService instance = InventarioService._internal();
  factory InventarioService() => instance;
  InventarioService._internal();

  // CU15 / RF21 - Consulta el stock por sucursal (y opcionalmente por variante)
  Future<List<Inventario>> listar({int? sucursalId, int? varianteId}) async {
    final params = <String>[];
    if (sucursalId != null) params.add('sucursal_id=$sucursalId');
    if (varianteId != null) params.add('variante_id=$varianteId');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';

    final response = await http.get(Uri.parse('${ApiClient.baseUrl}/inventario$query'));
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Inventario.fromJson(e)).toList();
  }

  // CU15 / RF20 - Registra stock inicial de una variante en una sucursal
  Future<Inventario> crear({
    required int varianteId,
    required int sucursalId,
    required int cantidad,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/inventario'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'variante_id': varianteId,
        'sucursal_id': sucursalId,
        'cantidad': cantidad,
      }),
    );
    _verificar(response);
    return Inventario.fromJson(jsonDecode(response.body));
  }

  // CU15 / RF22 - Actualiza cantidad/reservado (movimiento de inventario)
  Future<Inventario> actualizar(int id, {int? cantidad, int? cantidadReservada}) async {
    final body = <String, dynamic>{};
    if (cantidad != null) body['cantidad'] = cantidad;
    if (cantidadReservada != null) body['cantidad_reservada'] = cantidadReservada;

    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/inventario/$id'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode(body),
    );
    _verificar(response);
    return Inventario.fromJson(jsonDecode(response.body));
  }

  Future<void> eliminar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/inventario/$id'),
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
    return 'No se pudo completar la operación de inventario';
  }
}
