import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'api_client.dart';

class NotificacionesService {
  static final NotificacionesService instance =
      NotificacionesService._internal();
  factory NotificacionesService() => instance;
  NotificacionesService._internal();

  Future<List<Notificacion>> listarTodas() async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/notifications'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Notificacion.fromJson(e)).toList();
  }

  Future<List<Notificacion>> listarNoLeidas() async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/notifications/no-leidas'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Notificacion.fromJson(e)).toList();
  }

  Future<Notificacion> marcarComoLeida(int notificacionId) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/notifications/$notificacionId/leer'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    return Notificacion.fromJson(jsonDecode(response.body));
  }

  void _verificar(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extraerError(response.body));
    }
  }

  String _extraerError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {}
    return 'No se pudieron cargar las notificaciones';
  }
}
