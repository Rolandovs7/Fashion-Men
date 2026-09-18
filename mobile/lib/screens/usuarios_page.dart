import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/usuarios_service.dart';
import '../services/roles_service.dart';
import '../shared/admin_shell.dart';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU04 - Gestionar Usuarios
// RF: RF02 - Gestionar usuarios y roles
// CAPA: Flutter
// SERVICIO: services/usuarios_service.dart
// PANTALLA: screens/usuarios_page.dart
// BACKEND: GET/POST /api/usuarios, PUT/DELETE /api/usuarios/{id}
// Accesible desde AdminDrawer -> Configuración -> Usuarios.
// El selector de rol usa el catálogo dinámico de CU05 (RolesService)
// en vez de una lista fija ["cliente","administrador"].
// ============================================================
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final usuariosService = UsuariosService();
  final rolesService = RolesService();

  List<Usuario> usuarios = [];
  List<Rol> roles = [];
  bool cargando = true;
  String error = '';
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    _cargar();
    // CU05 / RF02 - roles disponibles para el selector de usuario
    rolesService.listar().then((r) {
      if (mounted) setState(() => roles = r);
    });
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);
    try {
      final resultado = await usuariosService.listar();
      setState(() {
        usuarios = resultado;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudieron cargar los usuarios.';
        cargando = false;
      });
    }
  }

  Future<void> _editar(Usuario usuario) async {
    final nombreCtrl = TextEditingController(text: usuario.nombre);
    final apellidoCtrl = TextEditingController(text: usuario.apellido);
    final emailCtrl = TextEditingController(text: usuario.email);
    String rol = usuario.rol;
    bool activo = usuario.activo;

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Editar usuario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: apellidoCtrl, decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: rol,
                  decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                  items: roles.isNotEmpty
                      ? roles.map((r) => DropdownMenuItem(value: r.nombre, child: Text(r.nombre))).toList()
                      : [DropdownMenuItem(value: rol, child: Text(rol))],
                  onChanged: (v) => setModalState(() => rol = v ?? 'cliente'),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  title: const Text('Usuario activo'),
                  value: activo,
                  onChanged: (v) => setModalState(() => activo = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (guardar != true) return;

    try {
      await usuariosService.actualizar(
        id: usuario.id,
        nombre: nombreCtrl.text.trim(),
        apellido: apellidoCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        activo: activo,
        rol: rol,
      );
      setState(() => mensaje = 'Usuario actualizado correctamente.');
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _crear() async {
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String rol = 'cliente';

    final crear = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nuevo usuario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: apellidoCtrl, decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: rol,
                  decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                  items: roles.isNotEmpty
                      ? roles.map((r) => DropdownMenuItem(value: r.nombre, child: Text(r.nombre))).toList()
                      : [DropdownMenuItem(value: rol, child: Text(rol))],
                  onChanged: (v) => setModalState(() => rol = v ?? 'cliente'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Crear usuario'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (crear != true) return;

    try {
      await usuariosService.crear(
        nombre: nombreCtrl.text.trim(),
        apellido: apellidoCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
        rol: rol,
      );
      setState(() => mensaje = 'Usuario creado correctamente.');
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _eliminar(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar a ${usuario.nombre} ${usuario.apellido}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, eliminar')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await usuariosService.eliminar(usuario.id);
      setState(() => mensaje = 'Usuario eliminado correctamente.');
      _cargar();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      titulo: 'Gestión de Usuarios',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo usuario'),
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
                  ...usuarios.map(
                    (u) => Card(
                      child: ListTile(
                        title: Text('${u.nombre} ${u.apellido}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${u.email} · ${u.rol}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(u.activo ? 'Activo' : 'Inactivo'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: u.activo ? Colors.green.shade50 : Colors.red.shade50,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editar(u),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _eliminar(u),
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
