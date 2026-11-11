import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../core/sesion.dart';
import '../db/database_helper.dart';
import 'api_client.dart';

/// Sincronización offline (POS):
/// - Guarda operaciones (ventas) en SQLite cuando no hay conexión.
/// - Las envía a `/api/sync/operaciones` con el JWT del usuario
///   (`Authorization: Bearer <token>` vía [ApiClient.jsonHeaders]).
///
/// [Fix 1.3] Ante 401/403 lanza [SesionExpiradaException] para que la
/// pantalla muestre el mensaje inline ("Tu sesión expiró...") con un
/// botón, sin cerrar la app ni redirigir automáticamente.
class OfflineSyncService {
  final _uuid = const Uuid();
  final Connectivity _connectivity = Connectivity();

  /// Escucha cambios de conexión y sincroniza lo pendiente al recuperar red.
  /// El JWT se toma del AuthService vigente en cada intento.
  void iniciarEscucha() {
    _connectivity.onConnectivityChanged.listen((results) async {
      final list = results;
      final hasConnection = list.contains(ConnectivityResult.mobile) ||
          list.contains(ConnectivityResult.wifi) ||
          list.contains(ConnectivityResult.ethernet) ||
          list.contains(ConnectivityResult.vpn);
      if (hasConnection) {
        try {
          await sincronizarPendientes();
        } catch (_) {
          // Sin sesión o sin conexión: se reintenta en el próximo cambio.
        }
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

  /// Envía las operaciones pendientes con el header Authorization vigente.
  Future<void> sincronizarPendientes() async {
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

    // [Fix 1.3] Misma baseUrl y JWT centralizado que el resto de la app.
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/sync/operaciones'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw SesionExpiradaException('Tu sesión expiró. Iniciá sesión de nuevo');
    }
    if (response.statusCode != 200) return;

    try {
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
    } catch (_) {
      // Respuesta inesperada: se mantienen las operaciones pendientes.
    }
  }
}
