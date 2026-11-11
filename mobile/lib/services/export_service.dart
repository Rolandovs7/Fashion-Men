import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'auth_service.dart';

/// ============================================================
/// CU22 - Exportación de reportes (móvil)
/// RF: Reportes PDF / Excel desde el cliente.
/// Genera documentos con el branding de la empresa autenticada
/// (nombre, logo vectorial y fecha) y los comparte con el
/// sistema operativo.
/// ============================================================
class ExportService {
  ExportService._();

  static const _negro = PdfColor.fromInt(0xFF0A0A0A);
  static const _ambar = PdfColor.fromInt(0xFFD97706);
  static const _gris = PdfColor.fromInt(0xFF525252);
  static const _claro = PdfColor.fromInt(0xFFF5F5F4);

  static String get _empresa => AuthService.instance.nombreEmpresa;

  static String _fecha() {
    final now = DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${now.year} $hh:$min';
  }

  static String _slug(String texto) => texto
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  /// Las fuentes estándar del PDF usan WinAnsi: se reemplazan
  /// caracteres fuera de ese rango (emojis, etc.) para evitar que
  /// la generación falle con nombres de clientes o productos.
  static String _pdfTexto(String valor) {
    return valor
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll(RegExp(r'[^\x20-\x7E\u00A0-\u00FF]'), '?');
  }

  /// Genera un PDF presentable y abre la hoja de compartir.
  static Future<void> exportarPdf({
    required String titulo,
    required List<String> columnas,
    required List<List<String>> filas,
    String? subtitulo,
  }) async {
    final empresa = _pdfTexto(_empresa);
    final tituloSeguro = _pdfTexto(titulo);
    final subtituloSeguro =
        subtitulo == null ? null : _pdfTexto(subtitulo);
    final columnasSeguras = columnas.map(_pdfTexto).toList();
    final filasSeguras = filas
        .map((fila) => fila.map(_pdfTexto).toList())
        .toList();
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 38,
                  height: 38,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: _negro,
                    borderRadius: pw.BorderRadius.circular(9),
                  ),
                  child: pw.Text(
                    empresa.isEmpty ? 'M' : empresa.substring(0, 1).toUpperCase(),
                    style: pw.TextStyle(
                      color: _ambar,
                      fontSize: 21,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        empresa.toUpperCase(),
                        style: pw.TextStyle(
                          color: _negro,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.Text(
                        'Reporte generado desde la aplicación móvil',
                        style: const pw.TextStyle(color: _gris, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                pw.Text(
                  'Emitido: ${_fecha()}',
                  style: const pw.TextStyle(color: _gris, fontSize: 9),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Container(height: 2, color: _ambar),
            pw.SizedBox(height: 12),
            pw.Text(
              tituloSeguro,
              style: pw.TextStyle(
                color: _negro,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (subtituloSeguro != null &&
                subtituloSeguro.trim().isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(
                subtituloSeguro,
                style: const pw.TextStyle(color: _gris, fontSize: 9.5),
              ),
            ],
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '$empresa · Documento generado electrónicamente',
              style: const pw.TextStyle(color: _gris, fontSize: 8),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(color: _gris, fontSize: 8),
            ),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: columnasSeguras,
            data: filasSeguras,
            border: null,
            headerDecoration: const pw.BoxDecoration(color: _negro),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(color: _negro, fontSize: 8),
            oddRowDecoration: const pw.BoxDecoration(color: _claro),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            cellAlignments: {
              for (var i = 0; i < columnasSeguras.length; i++)
                i: pw.Alignment.centerLeft,
            },
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Total de registros: ${filasSeguras.length}',
            style: pw.TextStyle(
              color: _negro,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await _compartir(
      bytes: bytes,
      nombre: 'reporte_${_slug(titulo)}_${_slug(empresa)}.pdf',
      mimeType: 'application/pdf',
      titulo: titulo,
    );
  }

  /// Genera un libro Excel (.xlsx) y abre la hoja de compartir.
  static Future<void> exportarExcel({
    required String titulo,
    required List<String> columnas,
    required List<List<String>> filas,
    String? subtitulo,
    String nombreHoja = 'Reporte',
  }) async {
    final empresa = _empresa;
    final excel = Excel.createExcel();
    final Sheet sheet = excel[nombreHoja];

    // Elimina la hoja por defecto para dejar solo la del reporte.
    if (excel.sheets.keys.contains('Sheet1') && nombreHoja != 'Sheet1') {
      excel.delete('Sheet1');
    }

    sheet.appendRow([TextCellValue(empresa.toUpperCase())]);
    sheet.appendRow([TextCellValue(titulo)]);
    if (subtitulo != null && subtitulo.trim().isNotEmpty) {
      sheet.appendRow([TextCellValue(subtitulo)]);
    }
    sheet.appendRow([TextCellValue('Emitido: ${_fecha()}')]);
    sheet.appendRow([]);
    sheet.appendRow(
      columnas.map<CellValue?>((c) => TextCellValue(c)).toList(),
    );

    for (final fila in filas) {
      sheet.appendRow(
        fila.map<CellValue?>((v) => TextCellValue(v)).toList(),
      );
    }
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Total de registros: ${filas.length}'),
    ]);

    for (var i = 0; i < columnas.length; i++) {
      sheet.setColumnWidth(i, 22);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('No se pudo generar el archivo Excel');
    }

    await _compartir(
      bytes: bytes,
      nombre: 'reporte_${_slug(titulo)}_${_slug(empresa)}.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      titulo: titulo,
    );
  }

  static Future<void> _compartir({
    required List<int> bytes,
    required String nombre,
    required String mimeType,
    required String titulo,
  }) async {
    final directorio = await getTemporaryDirectory();
    final archivo = File('${directorio.path}/$nombre');
    await archivo.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(archivo.path, mimeType: mimeType)],
        subject: titulo,
        text: '$titulo · $_empresa',
      ),
    );
  }
}
