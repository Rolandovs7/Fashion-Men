import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import '../core/config.dart';
import '../core/sesion.dart';

/// Configuración central de acceso a la API de MenStyle.
/// Todas las peticiones autenticadas deben usar [jsonHeaders]/[authHeaders]
/// o los helpers [get]/[post]/[put]/[delete] para inyectar el JWT.
class ApiClient {
  /// URL del backend. Por defecto apunta a producción (Render).
  /// Para desarrollo local, usa --dart-define=API_URL=http://localhost:8000/api
  static const String baseUrl = AppConfig.apiUrl;

  static String _token() => (AuthService.instance.token ?? '').trim();

  static Map<String, String> jsonHeaders({bool auth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = _token();
    if (auth && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, String> authHeaders() {
    final headers = <String, String>{};
    final token = _token();
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Uri uri(String path) => Uri.parse('$baseUrl$path');

  static Future<http.Response> get(String path, {bool auth = true}) =>
      http.get(uri(path), headers: auth ? authHeaders() : null);

  static Future<http.Response> post(String path, Object? body, {bool auth = true}) =>
      http.post(uri(path), headers: jsonHeaders(auth: auth), body: jsonEncode(body));

  static Future<http.Response> put(String path, Object? body, {bool auth = true}) =>
      http.put(uri(path), headers: jsonHeaders(auth: auth), body: jsonEncode(body));

  static Future<http.Response> delete(String path, {bool auth = true}) =>
      http.delete(uri(path), headers: authHeaders());

  static bool esErrorAuth(http.Response response) =>
      response.statusCode == 401 || response.statusCode == 403;

  static Future<Never> manejarErrorAuth() async {
    await AuthService.instance.limpiarSesion();
    throw SesionExpiradaException();
  }

  static String mensajeHttp(http.Response response, {String fallback = 'Error en la petición'}) {
    String detalle = fallback;
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['detail'] != null) {
        detalle = data['detail'].toString();
      } else if (data is Map && data['message'] != null) {
        detalle = data['message'].toString();
      }
    } catch (_) {
      final body = response.body.trim();
      if (body.isNotEmpty && body.length < 180) detalle = body;
    }
    final authMsg = response.statusCode == 401
        ? 'No autorizado'
        : response.statusCode == 403
            ? 'Acceso denegado'
            : null;
    final base = authMsg ?? detalle;
    return 'Error ${response.statusCode}: $base';
  }

  static Future<void> verificarRespuesta(http.Response response) async {
    if (esErrorAuth(response)) {
      await manejarErrorAuth();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = mensajeHttp(response);
      // ignore: avoid_print
      print('[ApiClient] $msg | ${response.request?.url}');
      throw Exception(msg);
    }
  }

  /// Decodifica JSON y verifica estado HTTP (incluye código en el error).
  static dynamic decodeChecked(http.Response response, {bool auth = true}) {
    // Nota: no async para no romper firmas; 401/403 se manejan como excepción síncrona
    // delegando limpieza al caller si es necesario. Preferir [verificarRespuesta] en flujos async.
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(mensajeHttp(response, fallback: 'Sesión inválida'));
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(mensajeHttp(response));
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }
}
