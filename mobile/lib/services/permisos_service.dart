import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_client.dart';

class PermisosService {
  static final PermisosService instance = PermisosService._internal();
  factory PermisosService() => instance;
  PermisosService._internal();

  Future<List<Permiso>> listar() async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/permisos'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Permiso.fromJson(e)).toList();
  }

  Future<List<Permiso>> porRol(String rol) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/permisos/rol/$rol'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Permiso.fromJson(e)).toList();
  }

  Future<void> asignar(String rol, int permisoId) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/permisos/asignar'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'rol': rol, 'permiso_id': permisoId}),
    );
    _verificar(response);
  }

  Future<void> quitar(String rol, int permisoId) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/permisos/quitar/$rol/$permisoId'),
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
    return 'No se pudo completar la operación de permisos';
  }
}
