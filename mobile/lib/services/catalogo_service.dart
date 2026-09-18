import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_client.dart';

class Talla {
  final int id;
  final String nombre;
  Talla({required this.id, required this.nombre});
  factory Talla.fromJson(Map<String, dynamic> json) =>
      Talla(id: json['id'], nombre: json['nombre']);
}

class ColorProducto {
  final int id;
  final String nombre;
  final String? codigoHex;
  ColorProducto({required this.id, required this.nombre, this.codigoHex});
  factory ColorProducto.fromJson(Map<String, dynamic> json) => ColorProducto(
        id: json['id'],
        nombre: json['nombre'],
        codigoHex: json['codigo_hex'],
      );
}

class CatalogoService {
  static final CatalogoService instance = CatalogoService._internal();
  factory CatalogoService() => instance;
  CatalogoService._internal();

  // ----- Consulta pública -----
  Future<List<Categoria>> listarCategorias({bool soloActivos = true}) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/categorias?solo_activos=$soloActivos'),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Categoria.fromJson(e)).toList();
  }

  Future<List<Producto>> listarProductos() async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/productos/'),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Producto.fromJson(e)).toList();
  }

  Future<Producto> obtenerProducto(int id) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/productos/$id'),
    );
    _verificar(response);
    return Producto.fromJson(jsonDecode(response.body));
  }

  Future<List<Variante>> listarVariantesPorProducto(int productoId) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/variantes/producto/$productoId'),
    );
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Variante.fromJson(e)).toList();
  }

  Future<Variante> obtenerVariante(int varianteId) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/variantes/$varianteId'),
    );
    _verificar(response);
    return Variante.fromJson(jsonDecode(response.body));
  }

  Future<List<Talla>> listarTallas() async {
    final response = await http.get(Uri.parse('${ApiClient.baseUrl}/tallas'));
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Talla.fromJson(e)).toList();
  }

  Future<List<ColorProducto>> listarColores() async {
    final response = await http.get(Uri.parse('${ApiClient.baseUrl}/colores'));
    _verificar(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => ColorProducto.fromJson(e)).toList();
  }

  // ----- Administración -----
  Future<Categoria> crearCategoria(String nombre, String? descripcion) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/categorias'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    _verificar(response);
    return Categoria.fromJson(jsonDecode(response.body));
  }

  Future<void> eliminarCategoria(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/categorias/$id'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
  }

  Future<Categoria> actualizarCategoria(int id, String nombre, String? descripcion) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/categorias/$id'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
    );
    _verificar(response);
    return Categoria.fromJson(jsonDecode(response.body));
  }

  Future<Producto> crearProducto({
    required String nombre,
    String? descripcion,
    required double precio,
    required int categoriaId,
    int? proveedorId,
    int? temporadaId,
    int? coleccionId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/productos/'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'categoria_id': categoriaId,
        'proveedor_id': proveedorId,
        'temporada_id': temporadaId,
        'coleccion_id': coleccionId,
      }),
    );
    _verificar(response);
    return Producto.fromJson(jsonDecode(response.body));
  }

  Future<void> eliminarProducto(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/productos/$id'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
  }

  Future<Producto> actualizarProducto({
    required int id,
    required String nombre,
    String? descripcion,
    required double precio,
    required int categoriaId,
    int? proveedorId,
    int? temporadaId,
    int? coleccionId,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/productos/$id'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'categoria_id': categoriaId,
        'proveedor_id': proveedorId,
        'temporada_id': temporadaId,
        'coleccion_id': coleccionId,
      }),
    );
    _verificar(response);
    return Producto.fromJson(jsonDecode(response.body));
  }

  Future<Talla> crearTalla(String nombre) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/tallas'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'nombre': nombre}),
    );
    _verificar(response);
    return Talla.fromJson(jsonDecode(response.body));
  }

  Future<void> eliminarTalla(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/tallas/$id'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
  }

  Future<ColorProducto> crearColor(String nombre, String? codigoHex) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/colores'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'nombre': nombre, 'codigo_hex': codigoHex}),
    );
    _verificar(response);
    return ColorProducto.fromJson(jsonDecode(response.body));
  }

  Future<void> eliminarColor(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiClient.baseUrl}/colores/$id'),
      headers: ApiClient.authHeaders(),
    );
    _verificar(response);
  }

  Future<Variante> crearVariante({
    required int productoId,
    required int tallaId,
    required int colorId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/variantes'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({
        'producto_id': productoId,
        'talla_id': tallaId,
        'color_id': colorId,
      }),
    );
    _verificar(response);
    return Variante.fromJson(jsonDecode(response.body));
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
    return 'No se pudo completar la operación del catálogo';
  }
}
