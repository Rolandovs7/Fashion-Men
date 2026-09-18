import 'dart:convert';
import 'package:http/http.dart' as http;

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU01 - Administrar Inicio de Sesión
// CU: CU02 - Administrar Cierre de Sesión
// RF: RF01 - Registrar clientes (registrar() relacionado)
// CAPA: Flutter
// SERVICIO: services/auth_service.dart
// PANTALLA: screens/login_page.dart, screens/registro_page.dart
// BACKEND: POST /api/auth/login, POST /api/auth/registro, GET /api/auth/me
// El token y el usuario actual viven en memoria (singleton); logout()
// los pone en null. No hay endpoint de logout (JWT sin blacklist).
// ============================================================
class AuthService {
  static final AuthService instance = AuthService._internal();

  factory AuthService() {
    return instance;
  }

  AuthService._internal();

  final String baseUrl = 'https://menstyle-api-n77g.onrender.com/api/auth';

  String? token;
  Map<String, dynamic>? usuarioActual;

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

    token = data['access_token'];

    if (token == null) {
      throw Exception('El servidor no devolvió el token');
    }

    return token!;
  }

  Future<Map<String, dynamic>> registrar({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password': password,
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

    if (response.statusCode != 200) {
      throw Exception(
        _extraerError(response.body, 'No se pudo obtener el usuario actual'),
      );
    }

    usuarioActual = jsonDecode(response.body);
    return usuarioActual!;
  }

  bool get esAdministrador => usuarioActual?['rol'] == 'administrador';

  void logout() {
    token = null;
    usuarioActual = null;
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
