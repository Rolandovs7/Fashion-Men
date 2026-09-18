import 'package:flutter/material.dart';
import '../services/roles_service.dart';
import '../shared/admin_shell.dart';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU05 - Gestionar Roles
// RF: RF02 - Gestionar usuarios y roles
// CAPA: Flutter
// SERVICIO: services/roles_service.dart
// PANTALLA: screens/roles_page.dart
// BACKEND: GET/POST /api/roles, PUT/DELETE /api/roles/{id}
// Equivalente a la pestaña "Roles" de admin-configuracion (Angular).
// Accesible desde AdminDrawer -> Configuración -> Roles.
// ============================================================
class RolesPage extends StatefulWidget {
  const RolesPage({super.key});

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  final rolesService = RolesService();

  List<Rol> roles = [];
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
      final resultado = await rolesService.listar(soloActivos: false);
      setState(() {
        roles = resultado;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudieron cargar los roles.';
        cargando = false;
      });
    }
  }

  Future<void> _crear() async {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final crear = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nuevo rol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej. encargado_sucursal)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Crear rol')),
          ],
        ),
      ),
    );

    if (crear != true || nombreCtrl.text.trim().isEmpty) return;

    try {
      await rolesService.crear(nombreCtrl.text.trim(), descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
      setState(() => mensaje = 'Rol creado correctamente.');
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _eliminar(Rol rol) async {
    if (rol.nombre == 'cliente' || rol.nombre == 'administrador') return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Desactivar el rol "${rol.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, desactivar')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await rolesService.eliminar(rol.id);
      setState(() => mensaje = 'Rol desactivado.');
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      titulo: 'Roles',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo rol'),
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
                  ...roles.map(
                    (rol) => Card(
                      child: ListTile(
                        title: Text(rol.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(rol.descripcion?.isNotEmpty == true ? rol.descripcion! : 'Sin descripción'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(rol.activo ? 'Activo' : 'Inactivo'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: rol.activo ? Colors.green.shade50 : Colors.red.shade50,
                            ),
                            if (rol.activo && rol.nombre != 'cliente' && rol.nombre != 'administrador')
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _eliminar(rol),
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
