/// ============================================================
/// Configuración central de la app MenStyle.
///
/// Fuente única de verdad para la URL del backend y otros
/// parámetros de entorno.
///
/// Uso:
///   - Por defecto: apunta al backend de producción en Render.
///   - Override al compilar:
///       flutter run --dart-define=API_URL=http://localhost:8000/api
///   - Override en VS Code: ver .vscode/launch.json
/// ============================================================
class AppConfig {
  AppConfig._();

  /// URL base del backend (sin /auth ni otros sufijos).
  /// Por defecto: producción en Render.
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://menstyle-api-n77g.onrender.com/api',
  );

  /// URL para el servicio de autenticación.
  static const String authUrl = '$apiUrl/auth';

  /// Timeout para requests HTTP (en segundos).
  static const int httpTimeoutSeconds = 30;

  /// Modo debug: imprime logs de requests.
  static const bool debugHttp = bool.fromEnvironment(
    'DEBUG_HTTP',
    defaultValue: false,
  );

  /// URL base para recursos estáticos (imágenes, etc.).
  /// Las imágenes viven en el frontend Angular (menstyle-web-0de9),
  /// no en el backend. Se puede override con --dart-define=MEDIA_URL=...
  static const String mediaBaseUrl = String.fromEnvironment(
    'MEDIA_URL',
    defaultValue: 'https://menstyle-web-0de9.onrender.com',
  );

  /// Convierte una ruta relativa como "/imagenes/x.jpg"
  /// a una URL absoluta como
  /// "https://menstyle-web-0de9.onrender.com/imagenes/x.jpg".
  /// Si la entrada ya es una URL absoluta (http/https), la devuelve tal cual.
  static String? urlCompleta(String? ruta) {
    if (ruta == null || ruta.isEmpty) return null;
    if (ruta.startsWith('http://') || ruta.startsWith('https://')) {
      return ruta;
    }
    final base = mediaBaseUrl.endsWith('/')
        ? mediaBaseUrl.substring(0, mediaBaseUrl.length - 1)
        : mediaBaseUrl;
    final path = ruta.startsWith('/') ? ruta : '/$ruta';
    return '$base$path';
  }
}
