import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_client.dart';

class ReservasService {
  static final ReservasService instance = ReservasService._internal();
  factory ReservasService() => instance;
  ReservasService._internal();

  Future<List<Reserva>> listarMisReservas() async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/reservas'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Reserva.fromJson(e)).toList();
  }

  Future<Reserva> crear({
    required int sucursalId,
    required DateTime fechaReserva,
    String? observaciones,
    required List<Map<String, int>> detalles,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/reservas'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'sucursal_id': sucursalId,
        'fecha_reserva': fechaReserva.toUtc().toIso8601String(),
        'observaciones': observaciones,
        'detalles': detalles,
      }),
    );
    _verificar(response);
    return Reserva.fromJson(jsonDecode(response.body));
  }

  Future<Reserva> cancelar(int reservaId) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/reservas/$reservaId/cancelar'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    return Reserva.fromJson(jsonDecode(response.body));
  }

  // ----- Administración -----
  Future<List<Reserva>> listarTodas({String? estado, int? sucursalId}) async {
    final params = <String>[];
    if (estado != null) params.add('estado=$estado');
    if (sucursalId != null) params.add('sucursal_id=$sucursalId');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';

    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/reservas/admin/todas$query'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Reserva.fromJson(e)).toList();
  }

  Future<Reserva> cambiarEstado(int reservaId, String nuevoEstado) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/reservas/$reservaId/estado'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'nuevo_estado': nuevoEstado}),
    );
    _verificar(response);
    return Reserva.fromJson(jsonDecode(response.body));
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
    return 'No se pudo completar la operación de la reserva';
  }
}
