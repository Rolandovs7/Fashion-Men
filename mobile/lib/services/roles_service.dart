import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

// ============================================================
// CU05 - Gestión de Roles
// RF02 - Gestionar usuarios y roles
// Espejo de roles.service.ts (Angular) y app/api/routes/roles.py
// (FastAPI). Catálogo dinámico: reemplaza la lista fija que antes
// tenían usuarios_page.dart y permisos_page.dart.
// ============================================================
class Rol {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  Rol({required this.id, required this.nombre, this.descripcion, required this.activo});

  factory Rol.fromJson(Map<String, dynamic> json) => Rol(
        id: json['id'],
        nombre: json['nombre'],
        descripcion: json['descripcion'],
        activo: json['activo'] ?? true,
      );
}

class RolesService {
  static final RolesService instance = RolesService._internal();
  factory RolesService() => instance;
  RolesService._internal();

  // CU05 / RF02 - Lista los roles activos (para selects de usuario/permiso)
  Future<List<Rol>> listar({bool soloActivos = true}) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/roles?solo_activos=$soloActivos'),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Rol.fromJson(e)).toList();
  }

  Future<Rol> crear(String nombre, String? descripcion) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/roles'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    _verificar(response);
    return Rol.fromJson(jsonDecode(response.body));
  }

  Future<void> eliminar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/roles/$id'),
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
    return 'No se pudo completar la operación de roles';
  }
}
