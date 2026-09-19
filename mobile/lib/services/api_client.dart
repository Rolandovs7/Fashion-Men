import 'auth_service.dart';
import '../core/config.dart';

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
}
