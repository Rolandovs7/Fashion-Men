import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import '../core/app_navigator.dart';
import '../core/config.dart';
import '../core/sesion.dart';
import '../screens/login_page.dart';

/// Configuración central de acceso a la API de MenStyle.
/// Todas las peticiones autenticadas deben usar [jsonHeaders]/[authHeaders]
/// o los helpers [get]/[post]/[put]/[delete] para inyectar el JWT.
class ApiClient {
  static bool _redirigiendoLogin = false;
  /// Contador (no bool) para que peticiones concurrentes envueltas en
  /// [sinRedireccionAutomatica] no reabran la redirección antes de tiempo.
  static int _supresionesRedireccion = 0;
  static bool get _suprimirRedireccion => _supresionesRedireccion > 0;
  static http.Response? _respuestaAuthPendiente;
  /// URL del backend. Por defecto apunta a producción (Render).
  /// Para desarrollo local, usa --dart-define=API_URL=http://localhost:8000/api
  static const String baseUrl = AppConfig.apiUrl;

  /// Se lee en cada petición (no al construir la pantalla) para usar siempre
  /// el token vigente de [AuthService], incluso tras un re-login.
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

  /// Solo un **401** significa que el token es inválido o expiró.
  ///
  /// Los códigos 400, 402, 403 y 422 son errores de negocio/validación
  /// (monto incorrecto, pedido ya pagado, sin permisos, datos inválidos) y
  /// deben llegar a la pantalla con el mensaje real del backend. Un 403
  /// NO debe cerrar la sesión ni mostrar "Tu sesión expiró".
  /// También se excluye el flujo de login/refresh: allí el 401 son
  /// credenciales incorrectas, no una sesión vencida.
  static bool esErrorAuth(http.Response response) {
    final path = (response.request?.url.path ?? '').toLowerCase();
    final esFlujoLogin = path.endsWith('/login') || path.contains('/refresh');
    if (esFlujoLogin) return false;
    final esAuth = response.statusCode == 401;
    // Se guarda la respuesta para que manejarErrorAuth() pueda distinguir
    // si el 401 corresponde al token vigente o a una petición rezagada.
    if (esAuth) _respuestaAuthPendiente = response;
    return esAuth;
  }

  /// [Fix 1.1 + 1.3 + Interceptor global] Cierra la sesión y redirige al
  /// Login (una sola vez) **solo ante un 401 real**.
  ///
  /// - Un 400/402/403/422 nunca llega aquí: [esErrorAuth] únicamente
  ///   devuelve true para 401, y además se valida el código como defensa.
  /// - Endpoints de pagos (`/pagos`) o dashboard (`/reportes`): un 401 NO
  ///   cierra la sesión ni redirige al Login. Se lanza
  ///   [SesionExpiradaException('Tu sesión expiró. Reintentá')] para que la
  ///   pantalla lo capture y muestre el mensaje inline con botón Reintentar.
  /// - Si la petición fallida llevaba un token distinto al vigente
  ///   (petición rezagada tras logout/re-login), NO borra la sesión nueva.
  /// - Con [sinRedireccionAutomatica] activo (flujos de pago) NO redirige:
  ///   la pantalla captura [SesionExpiradaException] y muestra el mensaje
  ///   inline sin cerrar la app.
  static Future<Never> manejarErrorAuth() async {
    final response = _respuestaAuthPendiente;
    _respuestaAuthPendiente = null;

    // Defensa extra: si por alguna razón se invoca con un error que no es
    // 401, se propaga el mensaje real del backend como error normal.
    if (response != null && response.statusCode != 401) {
      throw Exception(
        mensajeHttp(response, fallback: 'No se pudo completar la operación'),
      );
    }

    // Los flujos envueltos en [sinRedireccionAutomatica] (pago, checkout,
    // confirmación) y los endpoints de pagos/reportes NUNCA expulsan al
    // usuario: solo lanzan la excepción para que la pantalla muestre el
    // mensaje inline. Se evalúa también el flag porque una petición
    // concurrente (p. ej. sincronización de catálogo) podría haber dejado
    // su propia respuesta 401 en [_respuestaAuthPendiente].
    if (_suprimirRedireccion || _esEndpointSinRedireccion(response)) {
      throw SesionExpiradaException('Tu sesión expiró. Reintentá');
    }
    final vigente = response == null || _esPeticionVigente(response);
    if (vigente) {
      await AuthService.instance.limpiarSesion();
      if (!_suprimirRedireccion) _redirigirALogin();
    }
    throw SesionExpiradaException('Tu sesión expiró. Iniciá sesión de nuevo');
  }

  /// Endpoints cuyo 401 NO debe cerrar sesión ni expulsar al Login:
  /// pagos/confirmaciones (`/pagos`, `/payment`, `/confirmar`) y
  /// dashboard/reportes (`/reportes`).
  /// La pantalla que los consume captura [SesionExpiradaException] y
  /// muestra el mensaje inline "Tu sesión expiró. Reintentá".
  static bool _esEndpointSinRedireccion(http.Response? response) {
    final path = (response?.request?.url.path ?? '').toLowerCase();
    return path.contains('/pagos') ||
        path.contains('/payment') ||
        path.contains('/confirmar') ||
        path.contains('/reportes');
  }

  /// [Fix auth] Reinicia el estado estático del interceptor tras un
  /// logout/login. Evita que una redirección en curso o una respuesta
  /// 401 rezagada del usuario anterior afecten a la sesión nueva.
  static void reiniciarEstado() {
    _redirigiendoLogin = false;
    _supresionesRedireccion = 0;
    _respuestaAuthPendiente = null;
  }

  /// Indica si la petición que falló usaba el token actualmente vigente.
  /// Evita que 401 rezagados (token viejo o sin token) borren una sesión
  /// recién iniciada — causa raíz del bucle de logout.
  static bool _esPeticionVigente(http.Response response) {
    final req = response.request;
    final enviado =
        req is http.Request ? (req.headers['Authorization'] ?? '').trim() : '';
    final actual = _token();
    if (enviado.isEmpty) return actual.isEmpty;
    return enviado == 'Bearer $actual';
  }

  /// [Fix 1.3] Ejecuta [accion] (flujos de pago) SIN la redirección
  /// automática al Login ante un 401 real. La pantalla captura
  /// [SesionExpiradaException] y muestra "Tu sesión expiró..." inline
  /// con un botón, sin cerrar la app. Anidable y seguro ante llamadas
  /// concurrentes: usa un contador, no un booleano.
  static Future<T> sinRedireccionAutomatica<T>(Future<T> Function() accion) async {
    _supresionesRedireccion++;
    try {
      return await accion();
    } finally {
      if (_supresionesRedireccion > 0) _supresionesRedireccion--;
    }
  }

  /// [Fix 1.1] Redirige al Login una sola vez:
  /// - nunca durante un logout manual (`AuthService.isLoggingOut`);
  /// - nunca si ya hay un [LoginPage] abierto (evita Logins apilados);
  /// - nunca en paralelo si ya hay una redirección en curso.
  static void _redirigirALogin() {
    if (_redirigiendoLogin) return;
    if (AuthService.instance.isLoggingOut) return;
    if (LoginPage.abierto) return;
    final nav = AppNavigator.key.currentState;
    if (nav == null) return;
    _redirigiendoLogin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AuthService.instance.isLoggingOut || LoginPage.abierto) return;
      if (!nav.mounted) {
        _redirigiendoLogin = false;
        return;
      }
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      // El flag se libera cuando la LoginPage se cierra (dispose),
      // ver [liberarRedireccionLogin].
    });
  }

  /// Lo invoca [LoginPage] al cerrarse: rehabilita la redirección
  /// automática ante 401 (ya no hay un Login abierto).
  static void liberarRedireccionLogin() => _redirigiendoLogin = false;

  static String mensajeHttp(http.Response response, {String fallback = 'Error en la petición'}) {
    String? detalleBackend;
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['detail'] != null) {
        detalleBackend = data['detail'].toString();
      } else if (data is Map && data['message'] != null) {
        detalleBackend = data['message'].toString();
      }
    } catch (_) {
      final body = response.body.trim();
      if (body.isNotEmpty && body.length < 180) detalleBackend = body;
    }
    final authMsg = response.statusCode == 401
        ? 'No autorizado'
        : response.statusCode == 403
            ? 'Acceso denegado'
            : null;
    // Prioriza el mensaje real del backend (p. ej. "El monto no coincide",
    // "Ya existe un pago aprobado...") sobre el texto genérico de auth.
    final base = detalleBackend ?? authMsg ?? fallback;
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
