import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import '../core/config.dart';
import '../core/sesion.dart';

/// Configuración central de acceso a la API de MenStyle.
class ApiClient {
  /// URL del backend. Por defecto apunta a producción (Render).
  /// Para desarrollo local, usa --dart-define=API_URL=http://localhost:8000/api
  static const String baseUrl = AppConfig.apiUrl;

  static Map<String, String> jsonHeaders({bool auth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final token = AuthService.instance.token;
    if (auth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Map<String, String> authHeaders() {
    final headers = <String, String>{};
    final token = AuthService.instance.token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static bool esErrorAuth(http.Response response) =>
      response.statusCode == 401 || response.statusCode == 403;

  static Future<Never> manejarErrorAuth() async {
    await AuthService.instance.limpiarSesion();
    throw SesionExpiradaException();
  }

  static Future<void> verificarRespuesta(http.Response response) async {
    if (esErrorAuth(response)) {
      await manejarErrorAuth();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String mensaje = 'Error en la petición';
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['detail'] != null) {
          mensaje = data['detail'].toString();
        }
      } catch (_) {}
      throw Exception(mensaje);
    }
  }
}
