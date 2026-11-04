import 'dart:convert';
import 'package:http/http.dart' as http;
import '../db/database_helper.dart';

class CatalogoOfflineService {
  final String baseUrl = 'https://menstyle-api-n77g.onrender.com';

  Future<void> sincronizarCatalogo(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/productos/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final rows = data.map((p) {
        return {
          'id': p['id'],
          'nombre': p['nombre'],
          'precio': p['precio'],
          'imagen_url': p['imagen_url'],
          'stock': p['stock'] ?? 0,
          'empresa_id': p['empresa_id'],
        };
      }).toList();
      await DatabaseHelper.instance.insertProductos(rows);
    }
  }

  Future<List<Map<String, dynamic>>> obtenerProductosLocales() async {
    return await DatabaseHelper.instance.getProductos();
  }
}
