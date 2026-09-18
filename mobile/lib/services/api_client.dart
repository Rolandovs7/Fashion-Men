import 'auth_service.dart';

/// Configuración central de acceso a la API de MenStyle.
class ApiClient {
  /// Backend desplegado en la nube (mismo que usa el frontend web).
  static const String baseUrl = 'https://menstyle-api-n77g.onrender.com/api';

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
}
