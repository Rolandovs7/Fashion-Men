import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/permisos_service.dart';
import '../services/roles_service.dart';
import '../shared/admin_shell.dart';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU06 - Asignar Permisos (Riesgo: CRÍTICO)
// RF: RF02 - Gestionar usuarios y roles (relacionado; no hay un RF
//     explícito de "permisos" en el documento oficial de 25 RF)
// CAPA: Flutter
// SERVICIO: services/permisos_service.dart
// PANTALLA: screens/permisos_page.dart
// BACKEND: GET /api/permisos, GET /api/permisos/rol/{rol},
//          POST /api/permisos/asignar, DELETE /api/permisos/quitar/{rol}/{id}
// Accesible desde AdminDrawer -> Configuración -> Permisos.
// El selector de rol usa el catálogo dinámico de CU05 (RolesService)
// en vez de la lista fija ["administrador","cliente"].
// ============================================================
class PermisosPage extends StatefulWidget {
  const PermisosPage({super.key});

  @override
  State<PermisosPage> createState() => _PermisosPageState();
}

class _PermisosPageState extends State<PermisosPage> {
  final permisosService = PermisosService();
  final rolesService = RolesService();

  List<Permiso> permisos = [];
  List<Rol> roles = [];
  Set<int> permisosDelRol = {};
  String rolSeleccionado = 'administrador';

  bool cargando = true;
  bool guardando = false;
  String error = '';
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    rolesService.listar().then((r) {
      if (mounted) setState(() => roles = r);
    });
    _cargar();
  }

  // CU06 / RF02 - Consulta los permisos disponibles y los del rol activo
  Future<void> _cargar() async {
    setState(() => cargando = true);
    try {
      final resultados = await Future.wait([
        permisosService.listar(),
        permisosService.porRol(rolSeleccionado),
      ]);

      setState(() {
        permisos = resultados[0];
        permisosDelRol = (resultados[1]).map((p) => p.id).toSet();
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudieron cargar los permisos.';
        cargando = false;
      });
    }
  }

  Future<void> _cambiarRol(String rol) async {
    setState(() => rolSeleccionado = rol);
    _cargar();
  }

  // CU06 / RF02 - Asigna o quita un permiso del rol seleccionado
  Future<void> _alternarPermiso(Permiso permiso, bool activo) async {
    setState(() => guardando = true);
    try {
      if (activo) {
        await permisosService.asignar(rolSeleccionado, permiso.id);
      } else {
        await permisosService.quitar(rolSeleccionado, permiso.id);
      }
      setState(() {
        guardando = false;
        if (activo) {
          permisosDelRol.add(permiso.id);
        } else {
          permisosDelRol.remove(permiso.id);
        }
        mensaje = 'Permisos actualizados.';
      });
    } catch (e) {
      setState(() {
        guardando = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      titulo: 'Gestión de Permisos',
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (mensaje.isNotEmpty) _banner(mensaje, Colors.green),
                if (error.isNotEmpty) _banner(error, Colors.red),
                DropdownButtonFormField<String>(
                  initialValue: rolSeleccionado,
                  decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                  items: roles.isNotEmpty
                      ? roles.map((r) => DropdownMenuItem(value: r.nombre, child: Text(r.nombre))).toList()
                      : [DropdownMenuItem(value: rolSeleccionado, child: Text(rolSeleccionado))],
                  onChanged: (v) { if (v != null) _cambiarRol(v); },
                ),
                const SizedBox(height: 16),
                const Text('PERMISOS DISPONIBLES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                ...permisos.map(
                  (p) => Card(
                    child: CheckboxListTile(
                      value: permisosDelRol.contains(p.id),
                      onChanged: guardando ? null : (v) => _alternarPermiso(p, v ?? false),
                      title: Text(p.descripcion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(p.nombre, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                if (permisos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text('No hay permisos registrados.', style: TextStyle(color: Colors.grey))),
                  ),
              ],
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
