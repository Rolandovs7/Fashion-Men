import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/sesion.dart';
import '../core/theme.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/sesion_expirada_view.dart';

/// Dashboard ejecutivo para Administrador/SuperAdmin.
/// Consume GET /api/reportes/dashboard (DashboardResponse),
/// GET /api/reportes/ventas-por-mes (VentaMesResponse[]) y
/// - SuperAdmin: GET /api/reportes/ventas-por-empresa (VentaEmpresaResponse[])
/// - Admin:      GET /api/reportes/ventas-por-sucursal (VentaSucursalResponse[])
///
/// [Rediseño 2.5] Gráficos con fl_chart:
/// - Ventas por mes (barras).
/// - Predicción de Ventas (CU24): línea con ventas pasadas y
///   proyección a 3 meses (regresión lineal sobre la serie real).
/// - [Lote fix] Gráfico de torta: SuperAdmin ve "Ventas por Empresa"
///   y Admin ve "Ventas por Sucursal".
class AdminDashboardPage extends StatefulWidget {
  final bool embedded;
  const AdminDashboardPage({super.key, this.embedded = false});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _cargando = true;
  bool _sesionExpirada = false;
  String _error = '';
  Map<String, dynamic>? _data;

  /// Serie mensual: [{mes: '2026-01', total: 1234.5, cantidad_pedidos: 4}]
  List<Map<String, dynamic>> _serie = const [];

  /// Datos del gráfico de torta:
  /// - SuperAdmin: [{empresa_id, empresa, total_ventas, cantidad_pedidos}]
  /// - Admin: [{sucursal_id, sucursal, ciudad, total_ventas, cantidad_vendida}]
  List<Map<String, dynamic>> _torta = const [];

  /// Rol del usuario actual (define la vista del gráfico de torta).
  String get _rol => (AuthService.instance.usuarioActual?['rol'] ?? '').toString();
  bool get _esSuperAdmin => _rol == 'superadmin';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = '';
      _sesionExpirada = false;
    });
    try {
      // [Lote fix] El gráfico de torta depende del rol:
      // SuperAdmin → Ventas por Empresa; Admin → Ventas por Sucursal.
      final peticionTorta = _esSuperAdmin
          ? http.get(ApiClient.uri('/reportes/ventas-por-empresa'), headers: ApiClient.authHeaders())
          : http.get(ApiClient.uri('/reportes/ventas-por-sucursal'), headers: ApiClient.authHeaders());

      final results = await Future.wait([
        http.get(ApiClient.uri('/reportes/dashboard'), headers: ApiClient.authHeaders()),
        http.get(ApiClient.uri('/reportes/ventas-por-mes?meses=12'), headers: ApiClient.authHeaders()),
        peticionTorta,
      ]);
      final res = results[0];
      final resSerie = results[1];
      final resTorta = results[2];

      for (final r in results) {
        if (ApiClient.esErrorAuth(r)) {
          await ApiClient.manejarErrorAuth();
        }
      }

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = ApiClient.mensajeHttp(res, fallback: 'No se pudo cargar el dashboard');
        // ignore: avoid_print
        print('[AdminDashboardPage] $msg');
        throw Exception(msg);
      }

      List<Map<String, dynamic>> serie = const [];
      if (resSerie.statusCode >= 200 && resSerie.statusCode < 300) {
        final decodedSerie = jsonDecode(resSerie.body);
        if (decodedSerie is List) {
          serie = decodedSerie
              .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
              .toList();
        }
      }

      List<Map<String, dynamic>> torta = const [];
      if (resTorta.statusCode >= 200 && resTorta.statusCode < 300) {
        final decodedTorta = jsonDecode(resTorta.body);
        if (decodedTorta is List) {
          torta = decodedTorta
              .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
              .toList();
        }
      } else {
        // La torta no bloquea el resto del dashboard.
        // ignore: avoid_print
        print('[AdminDashboardPage] torta: ${ApiClient.mensajeHttp(resTorta)}');
      }

      final decoded = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        _data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
        _serie = serie;
        _torta = torta;
        _cargando = false;
      });
    } on SesionExpiradaException {
      if (!mounted) return;
      setState(() {
        _sesionExpirada = true;
        _cargando = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[AdminDashboardPage] Error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  // ==========================================================
  // Predicción CU24: regresión lineal simple sobre la serie real
  // y proyección de los próximos 3 meses.
  // ==========================================================
  List<FlSpot> get _spotsHistoricos {
    return [
      for (var i = 0; i < _serie.length; i++)
        FlSpot(i.toDouble(), ((_serie[i]['total'] as num?)?.toDouble() ?? 0)),
    ];
  }

  /// y = a + b·x ajustada por mínimos cuadrados sobre la serie histórica.
  List<FlSpot> _proyeccion() {
    final spots = _spotsHistoricos;
    if (spots.isEmpty) return const [];

    if (spots.length == 1) {
      // Sin tendencia calculable: proyección plana al valor actual.
      final y = spots.first.y;
      return [
        spots.first,
        FlSpot(3, y),
        FlSpot(4, y),
        FlSpot(5, y),
      ];
    }

    final n = spots.length;
    final sumX = spots.fold<double>(0, (s, p) => s + p.x);
    final sumY = spots.fold<double>(0, (s, p) => s + p.y);
    final sumXY = spots.fold<double>(0, (s, p) => s + p.x * p.y);
    final sumXX = spots.fold<double>(0, (s, p) => s + p.x * p.x);

    final denom = n * sumXX - sumX * sumX;
    final b = denom == 0 ? 0.0 : (n * sumXY - sumX * sumY) / denom;
    final a = (sumY - b * sumX) / n;

    double proyeccion(int x) => (a + b * x).clamp(0, double.infinity).toDouble();

    final ultimo = spots.last;
    return [
      ultimo, // conecta con la serie real
      FlSpot(ultimo.x + 1, proyeccion((ultimo.x + 1).toInt())),
      FlSpot(ultimo.x + 2, proyeccion((ultimo.x + 2).toInt())),
      FlSpot(ultimo.x + 3, proyeccion((ultimo.x + 3).toInt())),
    ];
  }

  String _etiquetaMes(int indice) {
    if (indice < 0 || indice >= _serie.length) return '';
    final mes = (_serie[indice]['mes'] ?? '').toString(); // '2026-01'
    if (mes.length < 7) return mes;
    const abreviados = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final m = int.tryParse(mes.substring(5, 7)) ?? 0;
    if (m >= 1 && m <= 12) return abreviados[m - 1];
    return mes;
  }

  /// Etiqueta de la proyección: meses siguientes al último real.
  String _etiquetaMesProyeccion(int indiceDesdeUltimo) {
    if (_serie.isEmpty) return '';
    final mes = (_serie.last['mes'] ?? '').toString();
    if (mes.length < 7) return '';
    var m = int.tryParse(mes.substring(5, 7)) ?? 1;
    for (var i = 0; i < indiceDesdeUltimo; i++) {
      m++;
      if (m > 12) m = 1;
    }
    const abreviados = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return abreviados[m - 1];
  }

  String _fmtCorto(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: content,
    );
  }

  Widget _buildContent() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    // [Lote fix] El 401 de /reportes NO expulsa al Login: mensaje inline
    // con botón Reintentar (ver ApiClient.manejarErrorAuth).
    if (_sesionExpirada) {
      return SesionExpiradaView(
        mensaje: 'Tu sesión expiró. Reintentá',
        onReintentar: _cargar,
      );
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    final d = _data ?? const {};
    final totalVentas = (d['total_ventas'] as num?)?.toDouble() ?? 0;
    final totalPedidos = (d['total_pedidos'] as num?)?.toInt() ?? 0;
    final totalProductos = (d['total_productos'] as num?)?.toInt() ?? 0;
    final totalSucursales = (d['total_sucursales'] as num?)?.toInt() ?? 0;
    final bajoStock = (d['productos_bajo_stock'] as num?)?.toInt() ?? 0;
    final clientes = (d['clientes_registrados'] as num?)?.toInt() ?? 0;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Métricas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Resumen del negocio', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _kpiPrincipal(
                  icon: Icons.payments_outlined,
                  color: Colors.green,
                  label: 'Total ventas',
                  value: 'Bs. ${totalVentas.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _kpiPrincipal(
                  icon: Icons.receipt_long_outlined,
                  color: Colors.blue,
                  label: 'Pedidos',
                  value: '$totalPedidos',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _kpiSmall(icon: Icons.checkroom_outlined, label: 'Productos', value: '$totalProductos')),
              const SizedBox(width: 12),
              Expanded(child: _kpiSmall(icon: Icons.store_outlined, label: 'Sucursales', value: '$totalSucursales')),
              const SizedBox(width: 12),
              Expanded(child: _kpiSmall(icon: Icons.people_outline, label: 'Clientes', value: '$clientes')),
            ],
          ),
          const SizedBox(height: 12),
          _kpiAlerta(bajoStock),
          const SizedBox(height: 24),

          // ---- Gráfico: Ventas por mes ----
          _cardGrafico(
            titulo: 'Ventas por mes',
            subtitulo: 'Últimos 12 meses (Bs)',
            icono: Icons.bar_chart_rounded,
            hijo: _graficoBarras(),
          ),
          const SizedBox(height: 16),

          // ---- Gráfico: torta (SuperAdmin → Empresa / Admin → Sucursal) ----
          _cardGrafico(
            titulo: _esSuperAdmin ? 'Ventas por Empresa' : 'Ventas por Sucursal',
            subtitulo: _esSuperAdmin
                ? 'Participación de cada empresa (Bs)'
                : 'Participación de cada sucursal (Bs)',
            icono: Icons.pie_chart_outline_rounded,
            hijo: _graficoTorta(),
          ),
          const SizedBox(height: 16),

          // ---- Gráfico: Predicción CU24 ----
          _cardGrafico(
            titulo: 'Predicción de Ventas (CU24)',
            subtitulo: 'Histórico real + proyección a 3 meses',
            icono: Icons.trending_up_rounded,
            hijo: _graficoPrediccion(),
            leyenda: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _cardGrafico({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Widget hijo,
    bool leyenda = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 20, color: AppTheme.bronce),
                const SizedBox(width: 8),
                Expanded(child: Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
              ],
            ),
            const SizedBox(height: 2),
            Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            hijo,
            if (leyenda) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _puntoLeyenda(AppTheme.negro, 'Ventas reales'),
                  const SizedBox(width: 16),
                  _puntoLeyenda(AppTheme.bronce, 'Proyección (regresión lineal)'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _puntoLeyenda(Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(texto, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _vacioGrafico(String mensaje) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(mensaje, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ------------------ Gráfico de barras: ventas por mes ------------------
  Widget _graficoBarras() {
    if (_serie.isEmpty) return _vacioGrafico('Sin ventas registradas aún.');

    final maxTotal = _serie.fold<double>(0, (m, e) => ((e['total'] as num?)?.toDouble() ?? 0) > m ? ((e['total'] as num?)?.toDouble() ?? 0) : m);
    final double maxY = (maxTotal * 1.25).clamp(10, double.infinity).toDouble();

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final total = rod.toY;
                return BarTooltipItem(
                  'Bs ${total.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            // [Lote fix] Labels con el valor de cada barra arriba del gráfico.
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= _serie.length) return const SizedBox.shrink();
                  final total = ((_serie[i]['total'] as num?)?.toDouble() ?? 0);
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _fmtCorto(total),
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.negro),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(_fmtCorto(value), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= _serie.length) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(_etiquetaMes(i), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < _serie.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: ((_serie[i]['total'] as num?)?.toDouble() ?? 0),
                    color: AppTheme.negro,
                    // [Lote fix] Barras más grandes y legibles.
                    width: 22,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ------------------ Torta: ventas por empresa/sucursal ------------------
  static const List<Color> _coloresTorta = [
    AppTheme.negro,
    AppTheme.amarilloMarca,
    AppTheme.bronce,
    Colors.blueGrey,
    Colors.teal,
    Colors.deepPurple,
  ];

  Widget _graficoTorta() {
    // Se descartan los valores en 0 para no ensuciar el gráfico.
    final datos = _torta
        .where((e) => ((e['total_ventas'] as num?)?.toDouble() ?? 0) > 0)
        .toList();
    if (datos.isEmpty) return _vacioGrafico('Sin ventas registradas aún.');

    final totalGeneral = datos.fold<double>(
      0,
      (s, e) => s + ((e['total_ventas'] as num?)?.toDouble() ?? 0),
    );

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              sections: [
                for (var i = 0; i < datos.length; i++)
                  () {
                    final total = ((datos[i]['total_ventas'] as num?)?.toDouble() ?? 0);
                    final color = _coloresTorta[i % _coloresTorta.length];
                    final porcentaje = totalGeneral > 0 ? total / totalGeneral * 100 : 0.0;
                    return PieChartSectionData(
                      value: total,
                      color: color,
                      radius: 34,
                      title: '${porcentaje.toStringAsFixed(0)}%',
                      titleStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color == AppTheme.amarilloMarca ? AppTheme.negro : Colors.white,
                      ),
                    );
                  }(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < datos.length; i++)
          _filaLeyendaTorta(
            datos[i],
            totalGeneral,
            _coloresTorta[i % _coloresTorta.length],
          ),
      ],
    );
  }

  /// Etiqueta de una porción: nombre de empresa (SuperAdmin) o sucursal (Admin).
  String _nombreTorta(Map<String, dynamic> d) {
    if (_esSuperAdmin) return (d['empresa'] ?? 'Empresa').toString();
    final sucursal = (d['sucursal'] ?? 'Sucursal').toString();
    final ciudad = (d['ciudad'] ?? '').toString();
    return ciudad.isEmpty ? sucursal : '$sucursal ($ciudad)';
  }

  Widget _filaLeyendaTorta(Map<String, dynamic> d, double totalGeneral, Color color) {
    final total = ((d['total_ventas'] as num?)?.toDouble() ?? 0);
    final porcentaje = totalGeneral > 0 ? total / totalGeneral * 100 : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_nombreTorta(d), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
          Text(
            'Bs ${total.toStringAsFixed(2)} · ${porcentaje.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ------------------ Línea: predicción CU24 ------------------
  Widget _graficoPrediccion() {
    final historicos = _spotsHistoricos;
    if (historicos.isEmpty) return _vacioGrafico('Sin datos para proyectar.');

    final proyeccion = _proyeccion();
    final todos = [...historicos, ...proyeccion.skip(1)];
    final double maxY = (todos.fold<double>(0, (m, p) => p.y > m ? p.y : m) * 1.2).clamp(10, double.infinity).toDouble();
    final totalPuntos = todos.length;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (totalPuntos - 1).toDouble(),
          maxY: maxY,
          lineTouchData: const LineTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(_fmtCorto(value), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  final cantidadHistorica = historicos.length;
                  if (i < 0 || i >= totalPuntos) return const SizedBox.shrink();
                  final etiqueta = i < cantidadHistorica
                      ? _etiquetaMes(i)
                      : _etiquetaMesProyeccion(i - cantidadHistorica + 1);
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      etiqueta,
                      style: TextStyle(
                        fontSize: 10,
                        color: i < cantidadHistorica ? Colors.grey.shade600 : AppTheme.bronce,
                        fontWeight: i < cantidadHistorica ? FontWeight.w400 : FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Histórico real
            LineChartBarData(
              spots: historicos,
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppTheme.negro,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: AppTheme.negro,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.amarilloMarca.withValues(alpha: 0.15),
              ),
            ),
            // Proyección (CU24): línea discontinua
            LineChartBarData(
              spots: proyeccion,
              isCurved: false,
              color: AppTheme.bronce,
              barWidth: 3,
              dashArray: const [6, 4],
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: AppTheme.bronce,
                  strokeWidth: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiPrincipal({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _kpiSmall({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _kpiAlerta(int bajoStock) {
    return Card(
      margin: EdgeInsets.zero,
      color: bajoStock > 0 ? Colors.orange.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: bajoStock > 0 ? Colors.orange.withValues(alpha: 0.4) : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 22,
              color: bajoStock > 0 ? Colors.orange.shade800 : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                bajoStock > 0 ? '$bajoStock producto(s) con stock bajo el mínimo' : 'Sin alertas de stock',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: bajoStock > 0 ? Colors.orange.shade900 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
