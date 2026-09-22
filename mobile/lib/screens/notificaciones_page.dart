import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/notificaciones_service.dart';
import '../core/theme.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  final notificacionesService = NotificacionesService();

  List<Notificacion> notificaciones = [];
  bool cargando = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      cargando = true;
      error = '';
    });

    try {
      final resultado = await notificacionesService.listarTodas();
      // Más recientes primero.
      resultado.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      setState(() {
        notificaciones = resultado;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudieron cargar tus notificaciones.';
        cargando = false;
      });
    }
  }

  Future<void> _marcarComoLeida(Notificacion n) async {
    if (n.leida) return;
    try {
      await notificacionesService.marcarComoLeida(n.id);
      _cargar();
    } catch (_) {
      // Si falla, simplemente no se marca; no interrumpimos al usuario.
    }
  }

  String _tiempoRelativo(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);
    if (diferencia.inMinutes < 1) return 'Ahora';
    if (diferencia.inMinutes < 60) return 'Hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'Hace ${diferencia.inHours} h';
    if (diferencia.inDays < 7) return 'Hace ${diferencia.inDays} d';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final noLeidas = notificaciones.where((n) => !n.leida).length;

    return Scaffold(
      backgroundColor: AppTheme.fondoPedidos,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Notificaciones'),
            if (noLeidas > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.bronce,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$noLeidas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error, textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargar,
              child: notificaciones.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 56,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No tienes notificaciones.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notificaciones.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final n = notificaciones[index];
                        return GestureDetector(
                          onTap: () => _marcarComoLeida(n),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: n.leida
                                  ? Colors.white
                                  : AppTheme.bronce.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: n.leida
                                    ? const Color(0xFFEDE7DC)
                                    : AppTheme.bronce.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: n.leida
                                        ? Colors.transparent
                                        : AppTheme.bronce,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n.titulo,
                                        style: TextStyle(
                                          fontWeight: n.leida
                                              ? FontWeight.w600
                                              : FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        n.mensaje,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _tiempoRelativo(n.fechaCreacion),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
