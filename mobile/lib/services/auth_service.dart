import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../db/database_helper.dart';
import 'api_client.dart';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU01 - Administrar Inicio de Sesión
// CU: CU02 - Administrar Cierre de Sesión
// RF: RF01 - Registrar clientes (registrar() relacionado)
// CAPA: Flutter
// SERVICIO: services/auth_service.dart
// PANTALLA: screens/login_page.dart, screens/registro_page.dart
// BACKEND: POST /api/auth/login, POST /api/auth/registro, GET /api/auth/me
// Token y usuario se persisten en SharedPreferences para mantener sesión.
// logout()/limpiarSesion() eliminan credenciales locales.
// ============================================================
class AuthService {
  static const _kToken = 'auth_token';
  static const _kUsuario = 'auth_usuario';

  static final AuthService instance = AuthService._internal();

  factory AuthService() {
    return instance;
  }

  AuthService._internal();

  final String baseUrl = AppConfig.authUrl;

  String? token;
  Map<String, dynamic>? usuarioActual;
  String? refreshToken;

  /// [Fix 1.1 - Logout bucle] true mientras se ejecuta un cierre de sesión.
  /// El interceptor de 401 de [ApiClient] consulta este flag para NO
  /// redirigir al Login (ni apilar Logins) durante el logout.
  bool _isLoggingOut = false;

  bool get isLoggingOut => _isLoggingOut;

  /// Nombre real de la empresa del usuario autenticado.
  /// Se usa para el branding dinámico (header, recibos, reportes).
  /// Fallback: MenStyle (tienda por defecto).
  String get nombreEmpresa {
    final nombre = (usuarioActual?['empresa_nombre'] ?? '').toString().trim();
    return nombre.isEmpty ? 'MenStyle' : nombre;
  }

  /// Empresas activas disponibles para el registro público.
  Future<List<Map<String, dynamic>>> listarEmpresasPublicas() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiUrl}/empresas/publicas'),
    );
    if (response.statusCode != 200) {
      throw Exception(_extraerError(response.body, 'No se pudieron cargar las empresas'));
    }
    final data = jsonDecode(response.body);
    if (data is! List) return [];
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_extraerError(response.body, 'No se pudo iniciar sesión'));
    }

    final data = jsonDecode(response.body);
    // [Fix auth] Nunca heredar credenciales de una sesión anterior.
    await _limpiarPersistencia();
    token = data['access_token'];

    if (token == null) {
      throw Exception('El servidor no devolvió el token');
    }

    ApiClient.reiniciarEstado();
    await _guardarSesion();
    // Login exitoso: se rehabilitan las redirecciones automáticas por 401.
    _isLoggingOut = false;
    // ignore: discarded_futures
    sincronizarCatalogoLocal();
    return token!;
  }

  Future<Map<String, dynamic>> registrar({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    int? empresaId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password': password,
        'empresa_id': ?empresaId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extraerError(response.body, 'No se pudo completar el registro'));
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> obtenerUsuarioActual() async {
    if (token == null) {
      throw Exception('No existe token');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await limpiarSesion();
      throw Exception('Sesión expirada');
    }

    if (response.statusCode != 200) {
      throw Exception(
        _extraerError(response.body, 'No se pudo obtener el usuario actual'),
      );
    }

    usuarioActual = jsonDecode(response.body);
    await _guardarSesion();
    return usuarioActual!;
  }

  bool get esAdministrador => usuarioActual?['rol'] == 'administrador';

  bool get tieneAccesoAdmin {
    if (usuarioActual == null) return false;
    return (usuarioActual!['rol'] ?? 'cliente') != 'cliente';
  }

  Future<bool> restaurarSesion() async {
    try {
      // Arranque limpio de la app: no hay logout en curso.
      _isLoggingOut = false;
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getString(_kToken);
      if (t == null || t.isEmpty) return false;
      token = t;
      final raw = prefs.getString(_kUsuario);
      if (raw != null && raw.isNotEmpty) {
        usuarioActual = jsonDecode(raw) as Map<String, dynamic>;
      }
      try {
        await obtenerUsuarioActual();
      } catch (_) {
        // Mantener token local si falla por red; 401/403 ya limpian.
      }
      if (token != null) {
        // ignore: discarded_futures
        sincronizarCatalogoLocal();
      }
      return token != null;
    } catch (_) {
      return false;
    }
  }

  /// Descarga el catálogo y lo guarda en SQLite para POS offline.
  /// Se dispara automáticamente tras login/restauración de sesión.
  Future<void> sincronizarCatalogoLocal() async {
    final t = token;
    if (t == null || t.isEmpty) {
      // ignore: avoid_print
      print('[SyncSQLite] Sin token, no se sincroniza catálogo.');
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/productos/'),
        headers: {'Authorization': 'Bearer $t'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // ignore: avoid_print
        print('[SyncSQLite] No se pudo descargar catálogo: HTTP ${response.statusCode} ${response.body}');
        return;
      }
      final data = jsonDecode(response.body);
      if (data is! List) {
        // ignore: avoid_print
        print('[SyncSQLite] Respuesta inesperada de productos (no es lista).');
        return;
      }
      final empresaId = usuarioActual?['empresa_id'];
      final rows = <Map<String, dynamic>>[];
      for (final e in data) {
        if (e is! Map) continue;
        if (e['activo'] == false) continue;
        rows.add({
          'id': e['id'],
          'nombre': e['nombre'] ?? 'Producto',
          'precio': (e['precio'] as num?)?.toDouble() ?? 0.0,
          'imagen_url': e['imagen_url'],
          'stock': 0,
          'empresa_id': empresaId ?? e['empresa_id'],
        });
      }
      await DatabaseHelper.instance.insertProductos(rows);
      // ignore: avoid_print
      print('[SyncSQLite] Catálogo sincronizado: ${rows.length} productos guardados en SQLite.');
    } catch (e) {
      // ignore: avoid_print
      print('[SyncSQLite] Error sincronizando catálogo local: $e');
    }
  }

  Future<void> _guardarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_kToken, token!);
    }
    if (usuarioActual != null) {
      await prefs.setString(_kUsuario, jsonEncode(usuarioActual));
    }
  }

  Future<void> limpiarSesion() async {
    await _limpiarPersistencia();
  }

  /// Limpia token, usuario y refresh token en memoria y en disco.
  /// Se usa tanto al cerrar sesión como antes de un nuevo login para que
  /// el siguiente usuario no herede las credenciales del anterior.
  Future<void> _limpiarPersistencia() async {
    token = null;
    usuarioActual = null;
    refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    // clear() equivale a deleteAll(): elimina todas las claves locales
    // (token, usuario, refresh y cualquier dato heredado de otra sesión).
    await prefs.clear();
  }

  /// [Fix 1.1 - Logout bucle] Cierre de sesión único e idempotente.
  ///
  /// - Borra token, usuario y refreshToken de SharedPreferences con `await`
  ///   ANTES de devolver el control: el caller navega al Login recién cuando
  ///   la sesión local ya quedó limpia.
  /// - Deja [_isLoggingOut] en true (se libera con un login exitoso o al
  ///   restaurar sesión) para que los 401 rezagados de peticiones en vuelo
  ///   no redirijan al Login ni apilen pantallas durante el logout.
  Future<void> logout() async {
    if (_isLoggingOut) return; // nunca dos logout simultáneos
    _isLoggingOut = true;
    await _limpiarPersistencia();
    // Descarta cualquier redirección/401 pendiente del usuario anterior.
    ApiClient.reiniciarEstado();
  }

  String _extraerError(String body, String mensajePorDefecto) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
    } catch (_) {
      // El cuerpo no era JSON válido; se usa el mensaje por defecto.
    }
    return mensajePorDefecto;
  }
}
