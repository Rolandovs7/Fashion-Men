import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/sesion.dart';
import '../core/theme.dart';
import '../services/api_client.dart';
import '../shared/admin_shell.dart';
import '../widgets/sesion_expirada_view.dart';

/// ============================================================
/// TRAZABILIDAD MENSTYLE
/// CU: CU23 - Reportes Generativos (Asistente IA / Text-to-SQL)
/// RF: RF25 - Proporcionar funcionalidad basada en IA
/// CAPA: Flutter | BACKEND: POST /api/ia/consultar
/// ============================================================
/// Chat con el Asistente IA para administradores: el usuario
/// escribe una pregunta en lenguaje natural, el backend la traduce
/// a SQL seguro (solo SELECT, filtrado por empresa) y devuelve
/// {sql, columnas, resultados, mensaje}.
///
/// El botón de micrófono queda preparado: requiere agregar el
/// paquete `speech_to_text` al pubspec.yaml para activarse.
class AsistenteIaPage extends StatefulWidget {
  final bool embedded;
  const AsistenteIaPage({super.key, this.embedded = false});

  @override
  State<AsistenteIaPage> createState() => _AsistenteIaPageState();
}

/// Mensaje del chat: del usuario o del asistente (con su tabla de resultados).
class _Mensaje {
  final bool esUsuario;
  final String texto;
  final String? sql;
  final List<String> columnas;
  final List<Map<String, dynamic>> filas;
  bool sqlVisible;

  _Mensaje({
    required this.esUsuario,
    required this.texto,
    this.sql,
    this.columnas = const [],
    this.filas = const [],
  }) : sqlVisible = false;
}

const List<String> _sugerencias = [
  '¿Cuáles son los productos más vendidos?',
  '¿Cuántas ventas hubo el último mes?',
  '¿Qué clientes compraron más?',
  'Stock disponible por sucursal',
];

class _AsistenteIaPageState extends State<AsistenteIaPage> {
  final _preguntaController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Mensaje> _mensajes = [];

  bool _enviando = false;
  bool _sesionExpirada = false;
  String _error = '';
  String? _ultimaPregunta;

  @override
  void dispose() {
    _preguntaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _hacerScrollAbajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // CU23 / POST /api/ia/consultar - pregunta en lenguaje natural.
  Future<void> _enviarPregunta([String? preguntaPreCargada]) async {
    final pregunta =
        (preguntaPreCargada ?? _preguntaController.text).trim();
    if (pregunta.isEmpty || _enviando) return;

    _ultimaPregunta = pregunta;
    setState(() {
      _enviando = true;
      _error = '';
      _sesionExpirada = false;
      _mensajes.add(_Mensaje(esUsuario: true, texto: pregunta));
    });
    _preguntaController.clear();
    _hacerScrollAbajo();

    try {
      final res = await http.post(
        ApiClient.uri('/ia/consultar'),
        headers: ApiClient.jsonHeaders(),
        body: jsonEncode({'pregunta': pregunta}),
      );
      if (ApiClient.esErrorAuth(res)) {
        await ApiClient.manejarErrorAuth();
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = ApiClient.mensajeHttp(
          res,
          fallback: 'No se pudo consultar al asistente',
        );
        // ignore: avoid_print
        print('[AsistenteIaPage] consultar: $msg');
        throw Exception(msg);
      }

      final data = jsonDecode(res.body);
      final columnas = (data['columnas'] as List? ?? const [])
          .map((e) => e.toString())
          .toList();
      final filas = (data['resultados'] as List? ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      final mensaje = (data['mensaje'] ?? '').toString();

      setState(() {
        _mensajes.add(_Mensaje(
          esUsuario: false,
          texto: mensaje.isNotEmpty ? mensaje : 'Esta es la respuesta a tu consulta.',
          sql: (data['sql'] ?? '').toString(),
          columnas: columnas,
          filas: filas,
        ));
        _enviando = false;
      });
    } on SesionExpiradaException {
      if (!mounted) return;
      setState(() {
        _sesionExpirada = true;
        _enviando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _enviando = false;
      });
    } finally {
      _hacerScrollAbajo();
    }
  }

  /// [Preparado] Micrófono: requiere el paquete `speech_to_text`
  /// en pubspec.yaml (todavía no está incluido).
  void _microfono() {
    // [Segundo Parcial] Micrófono preparado para integración futura.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El micrófono estará disponible próximamente.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      titulo: 'Asistente IA',
      embedded: widget.embedded,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_sesionExpirada) {
      return SesionExpiradaView(
        mensaje: 'Tu sesión expiró. Reintentá',
        onReintentar: _reintentarUltimaPregunta,
      );
    }

    return Column(
      children: [
        Expanded(child: _listaMensajes()),
        _barraError(),
        _barraEntrada(),
      ],
    );
  }

  /// Reenvía la última pregunta (quedó sin respuesta al fallar la sesión).
  Future<void> _reintentarUltimaPregunta() async {
    if (_mensajes.isNotEmpty && _mensajes.last.esUsuario) {
      setState(() => _mensajes.removeLast());
    }
    setState(() => _sesionExpirada = false);
    await _enviarPregunta(_ultimaPregunta);
  }

  Widget _listaMensajes() {
    if (_mensajes.isEmpty && _error.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.smart_toy_outlined, size: 56, color: AppTheme.bronce),
          const SizedBox(height: 12),
          const Text(
            'Asistente IA de reportes',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Preguntá en lenguaje natural sobre tus ventas, productos, '
            'clientes o stock. El asistente traduce tu pregunta a una '
            'consulta segura sobre los datos de tu empresa (CU23).',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sugerencia in _sugerencias)
                ActionChip(
                  avatar: const Icon(Icons.bolt, size: 16, color: AppTheme.bronce),
                  label: Text(sugerencia),
                  onPressed: () => _enviarPregunta(sugerencia),
                ),
            ],
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _mensajes.length + (_enviando ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _mensajes.length) {
          return _burbujaAsistente(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text('Consultando...', style: TextStyle(fontSize: 12.5)),
              ],
            ),
          );
        }
        final mensaje = _mensajes[index];
        if (mensaje.esUsuario) {
          return Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10, left: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.negro,
                borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(4)),
              ),
              child: Text(
                mensaje.texto,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
              ),
            ),
          );
        }
        return _burbujaRespuesta(mensaje);
      },
    );
  }

  Widget _burbujaAsistente({required Widget child}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
        ),
        child: child,
      ),
    );
  }

  Widget _burbujaRespuesta(_Mensaje mensaje) {
    return _burbujaAsistente(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mensaje.texto, style: const TextStyle(fontSize: 13.5)),
          if (mensaje.filas.isNotEmpty) ...[
            const SizedBox(height: 10),
            _tablaResultado(mensaje),
          ],
          if ((mensaje.sql ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => mensaje.sqlVisible = !mensaje.sqlVisible),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mensaje.sqlVisible ? Icons.expand_less : Icons.code,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mensaje.sqlVisible ? 'Ocultar SQL' : 'Ver SQL generado',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (mensaje.sqlVisible)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  mensaje.sql!,
                  style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', height: 1.4),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Tabla con los resultados devueltos por el asistente (máx. 15 filas).
  Widget _tablaResultado(_Mensaje mensaje) {
    final filas = mensaje.filas.take(15).toList();
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.black87),
            dataTextStyle: const TextStyle(fontSize: 11),
            columnSpacing: 16,
            headingRowHeight: 34,
            dataRowMinHeight: 32,
            columns: [
              for (final col in mensaje.columnas)
                DataColumn(label: Text(col, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
            rows: [
              for (final fila in filas)
                DataRow(
                  cells: [
                    for (final col in mensaje.columnas)
                      DataCell(
                        Text(
                          '${fila[col] ?? '—'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barraError() {
    if (_error.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
    );
  }

  Widget _barraEntrada() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _preguntaController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (v) => _enviarPregunta(),
                decoration: const InputDecoration(
                  hintText: 'Preguntá algo sobre tu negocio...',
                  prefixIcon: Icon(Icons.smart_toy_outlined),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Micrófono: preparado para speech_to_text (no está en pubspec).
            IconButton(
              tooltip: 'Búsqueda por voz (próximamente)',
              onPressed: _enviando ? null : _microfono,
              icon: const Icon(Icons.mic_none_outlined),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              tooltip: 'Enviar',
              onPressed: _enviando ? null : () => _enviarPregunta(),
              icon: _enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
