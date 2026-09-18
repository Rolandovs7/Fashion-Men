import 'package:flutter/material.dart';
import '../services/tipos_pago_service.dart';
import '../shared/admin_shell.dart';

// ============================================================
// CU19 - Pantalla de Gestión de Tipos de Pago
// RF18 - Permitir pagos en punto de caja
// RF19 - Integrar una pasarela de pago (sandbox propio)
// Equivalente a la pestaña "Tipos de Pago" de admin-configuracion (Angular).
// ============================================================
class TiposPagoPage extends StatefulWidget {
  const TiposPagoPage({super.key});

  @override
  State<TiposPagoPage> createState() => _TiposPagoPageState();
}

class _TiposPagoPageState extends State<TiposPagoPage> {
  final tiposPagoService = TiposPagoService();

  List<TipoPago> tipos = [];
  bool cargando = true;
  String error = '';
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    try {
      final resultado = await tiposPagoService.listar(soloActivos: false);
      setState(() {
        tipos = resultado;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudieron cargar los tipos de pago.';
        cargando = false;
      });
    }
  }

  Future<void> _crear() async {
    final nombreCtrl = TextEditingController();

    final crear = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nuevo tipo de pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej. transferencia)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Crear tipo de pago')),
          ],
        ),
      ),
    );

    if (crear != true || nombreCtrl.text.trim().isEmpty) return;

    try {
      await tiposPagoService.crear(nombreCtrl.text.trim());
      setState(() => mensaje = 'Tipo de pago creado correctamente.');
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _eliminar(TipoPago tipo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Desactivar el tipo de pago "${tipo.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, desactivar')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await tiposPagoService.eliminar(tipo.id);
      setState(() => mensaje = 'Tipo de pago desactivado.');
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      titulo: 'Tipos de Pago',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo tipo'),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (mensaje.isNotEmpty) _banner(mensaje, Colors.green),
                  if (error.isNotEmpty) _banner(error, Colors.red),
                  ...tipos.map(
                    (tipo) => Card(
                      child: ListTile(
                        title: Text(tipo.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(tipo.activo ? 'Activo' : 'Inactivo'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: tipo.activo ? Colors.green.shade50 : Colors.red.shade50,
                            ),
                            if (tipo.activo)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _eliminar(tipo),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _banner(String texto, Color color) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );
}
