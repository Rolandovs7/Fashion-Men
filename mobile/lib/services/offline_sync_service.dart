import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';

class OfflineSyncService {
  final String baseUrl = 'https://menstyle-api-n77g.onrender.com';
  final _uuid = const Uuid();
  final Connectivity _connectivity = Connectivity();

  void iniciarEscucha(String token) {
    _connectivity.onConnectivityChanged.listen((results) async {
      final list = results;
      final hasConnection = list.contains(ConnectivityResult.mobile) || list.contains(ConnectivityResult.wifi) || list.contains(ConnectivityResult.ethernet) || list.contains(ConnectivityResult.vpn);
      if (hasConnection) {
        await sincronizarPendientes(token);
      }
    });
  }

  Future<String> guardarOperacionOffline(Map<String, dynamic> operacion) async {
    final uuid = _uuid.v4();
    await DatabaseHelper.instance.insertOperacionPendiente({
      'uuid': uuid,
      'tipo': operacion['tipo'],
      'datos_json': jsonEncode(operacion),
      'estado': 'pendiente',
      'fecha': DateTime.now().toIso8601String(),
    });
    return uuid;
  }

  Future<void> sincronizarPendientes(String token) async {
    final pendientes = await DatabaseHelper.instance.getOperacionesPendientes();
    if (pendientes.isEmpty) return;
    final payload = <Map<String, dynamic>>[];
    for (var op in pendientes) {
      try {
        final datos = jsonDecode(op['datos_json']);
        payload.add({
          'uuid': op['uuid'],
          'tipo': op['tipo'],
          'productos': datos['productos'],
          'monto': datos['monto'],
          'sucursal_id': datos['sucursal_id'],
          'datosExtra': datos['datosExtra'],
        });
      } catch (_) {}
    }
    if (payload.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sync/operaciones'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final resultados = res['resultados'] ?? [];
        for (var r in resultados) {
          final uuid = r['uuid'];
          final estado = r['estado'];
          if (estado == 'SINCRONIZADO' || estado == 'ya_sincronizado') {
            await DatabaseHelper.instance.deleteOperacionPendiente(uuid);
          } else if (estado == 'CONFLICTO') {
            await DatabaseHelper.instance.updateOperacionPendiente(uuid, 'Conflicto');
          } else if (estado == 'ERROR') {
            await DatabaseHelper.instance.updateOperacionPendiente(uuid, 'ERROR');
          }
        }
      }
    } catch (e) {
      // mantener pendientes
    }
  }
}
