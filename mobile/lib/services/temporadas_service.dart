import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_client.dart';

class TemporadasService {
  static final TemporadasService instance = TemporadasService._internal();
  factory TemporadasService() => instance;
  TemporadasService._internal();

  Future<List<Temporada>> listar({bool soloActivos = false}) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/temporadas?solo_activos=$soloActivos'),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Temporada.fromJson(e)).toList();
  }

  Future<Temporada> crear({required String nombre, String? descripcion}) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/temporadas'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    _verificar(response);
    return Temporada.fromJson(jsonDecode(response.body));
  }

  Future<void> eliminar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/temporadas/$id'),
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
    return 'No se pudo completar la operación de temporadas';
  }
}
