import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_client.dart';

class UsuariosService {
  static final UsuariosService instance = UsuariosService._internal();
  factory UsuariosService() => instance;
  UsuariosService._internal();

  Future<List<Usuario>> listar() async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/usuarios'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Usuario.fromJson(e)).toList();
  }

  Future<Usuario> crear({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String rol,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/usuarios'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password': password,
        'rol': rol,
      }),
    );
    _verificar(response);
    return Usuario.fromJson(jsonDecode(response.body));
  }

  Future<Usuario> actualizar({
    required int id,
    required String nombre,
    required String apellido,
    required String email,
    required bool activo,
    required String rol,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/usuarios/$id'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'activo': activo,
        'rol': rol,
      }),
    );
    _verificar(response);
    return Usuario.fromJson(jsonDecode(response.body));
  }

  Future<void> eliminar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/usuarios/$id'),
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
    return 'No se pudo completar la operación de usuarios';
  }
}
