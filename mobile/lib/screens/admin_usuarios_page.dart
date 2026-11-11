import 'package:flutter/material.dart';

import '../core/sesion.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../services/roles_service.dart';
import '../services/usuarios_service.dart';
import '../shared/admin_shell.dart';
import '../widgets/sesion_expirada_view.dart';

// ============================================================
// CU04 - Gestionar Usuarios (panel por empresa)
// RF02 - Gestionar usuarios y roles
// BACKEND: GET /api/empresas/{id}/usuarios, PUT /api/usuarios/{id}
// ============================================================
// Lista los clientes/usuarios de la empresa del administrador con
// nombre, email, teléfono, fecha de registro y estado. Permite
// editar (nombre, apellido, email, teléfono y rol) y
// activar/desactivar la cuenta con confirmación.
class AdminUsuariosPage extends StatefulWidget {
  final bool embedded;

  /// Empresa a consultar. Si es null se usa la del usuario logueado.
  final int? empresaId;

  const AdminUsuariosPage({super.key, this.embedded = false, this.empresaId});

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  final usuariosService = UsuariosService();
  final rolesService = RolesService();
  final buscarController = TextEditingController();

  List<Usuario> usuarios = [];
  List<Rol> roles = [];
  bool cargando = true;
  bool sesionExpirada = false;
  bool exportando = false;
  String error = '';
  String busqueda = '';

  int? get _empresaId {
    if (widget.empresaId != null) return widget.empresaId;
    final id = AuthService.instance.usuarioActual?['empresa_id'];
    if (id is int) return id;
    return int.tryParse('${id ?? ''}');
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      cargando = true;
      error = '';
      sesionExpirada = false;
    });

    final empresaId = _empresaId;
    if (empresaId == null) {
      setState(() {
        cargando = false;
        error = 'Tu usuario no tiene una empresa asignada.';
      });
      return;
    }

    try {
      final lista = await usuariosService.listarPorEmpresa(empresaId);

      // Catálogo dinámico de roles (CU05). Si falla, se usan los roles
      // ya presentes en la lista para no bloquear la pantalla.
      List<Rol> catalogo = [];
      try {
        catalogo = await rolesService.listar();
      } catch (e) {
        // ignore: avoid_print
        print('[AdminUsuariosPage] roles: $e');
      }

      if (!mounted) return;
      setState(() {
        usuarios = lista;
        roles = catalogo;
        cargando = false;
      });
    } on SesionExpiradaException {
      if (!mounted) return;
      setState(() {
        sesionExpirada = true;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        cargando = false;
      });
    }
  }

  List<Usuario> get _filtrados {
    final q = busqueda.trim().toLowerCase();
    if (q.isEmpty) return usuarios;
    return usuarios.where((u) {
      return u.nombreCompleto.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          (u.telefono ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<String> get _opcionesRol {
    final nombres = roles.map((r) => r.nombre).toSet();
    if (nombres.isEmpty) {
      nombres.addAll(['cliente', 'administrador']);
    }
    return nombres.toList()..sort();
  }

  String _fechaCorta(String? fecha) {
    if (fecha == null || fecha.isEmpty) return '—';
    return fecha.length >= 10 ? fecha.substring(0, 10) : fecha;
  }

  List<String> get _columnasReporte => const [
        'Nombre',
        'Email',
        'Teléfono',
        'Rol',
        'Registro',
        'Estado',
      ];

  List<List<String>> get _filasReporte => _filtrados
      .map(
        (u) => [
          u.nombreCompleto,
          u.email,
          u.telefono ?? '—',
          u.rol,
          _fechaCorta(u.fechaRegistro),
          u.activo ? 'Activo' : 'Inactivo',
        ],
      )
      .toList();

  Future<void> _exportarPdf() async {
    if (_filtrados.isEmpty) {
      _avisar('No hay usuarios para exportar.');
      return;
    }
    setState(() => exportando = true);
    try {
      await ExportService.exportarPdf(
        titulo: 'Usuarios de la empresa',
        subtitulo: 'Listado de usuarios/clientes registrados',
        columnas: _columnasReporte,
        filas: _filasReporte,
      );
    } catch (e) {
      _avisar('No se pudo generar el PDF: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => exportando = false);
    }
  }

  Future<void> _exportarExcel() async {
    if (_filtrados.isEmpty) {
      _avisar('No hay usuarios para exportar.');
      return;
    }
    setState(() => exportando = true);
    try {
      await ExportService.exportarExcel(
        titulo: 'Usuarios de la empresa',
        subtitulo: 'Listado de usuarios/clientes registrados',
        columnas: _columnasReporte,
        filas: _filasReporte,
        nombreHoja: 'Usuarios',
      );
    } catch (e) {
      _avisar('No se pudo generar el Excel: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => exportando = false);
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _editar(Usuario usuario) async {
    final nombreCtrl = TextEditingController(text: usuario.nombre);
    final apellidoCtrl = TextEditingController(text: usuario.apellido);
    final emailCtrl = TextEditingController(text: usuario.email);
    final telefonoCtrl = TextEditingController(text: usuario.telefono ?? '');
    final opciones = {..._opcionesRol, usuario.rol}.toList()..sort();
    var rolSeleccionado = opciones.contains(usuario.rol) ? usuario.rol : opciones.first;
    var activo = usuario.activo;

    final resultado = await showDialog<_DatosEdicion>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar usuario', style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: apellidoCtrl,
                  decoration: const InputDecoration(labelText: 'Apellido *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: rolSeleccionado,
                  decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                  items: [
                    for (final rol in opciones)
                      DropdownMenuItem(value: rol, child: Text(rol)),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => rolSeleccionado = v);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cuenta activa'),
                  value: activo,
                  onChanged: (v) => setDialogState(() => activo = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final nombre = nombreCtrl.text.trim();
                final apellido = apellidoCtrl.text.trim();
                final email = emailCtrl.text.trim();
                if (nombre.isEmpty || apellido.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Completá nombre, apellido y email.')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(
                  _DatosEdicion(
                    nombre: nombre,
                    apellido: apellido,
                    email: email,
                    telefono: telefonoCtrl.text.trim(),
                    rol: rolSeleccionado,
                    activo: activo,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    emailCtrl.dispose();
    telefonoCtrl.dispose();

    if (resultado == null) return;

    try {
      await usuariosService.actualizar(
        id: usuario.id,
        nombre: resultado.nombre,
        apellido: resultado.apellido,
        email: resultado.email,
        telefono: resultado.telefono.isEmpty ? null : resultado.telefono,
        activo: resultado.activo,
        rol: resultado.rol,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario ${resultado.nombre} actualizado.')),
      );
      await _cargar();
    } on SesionExpiradaException {
      if (!mounted) return;
      setState(() => sesionExpirada = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _cambiarActivo(Usuario usuario) async {
    final accion = usuario.activo ? 'desactivar' : 'activar';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿${usuario.activo ? 'Desactivar' : 'Activar'} usuario?'),
        content: Text(
          '¿Seguro que querés $accion a ${usuario.nombreCompleto}? '
          '${usuario.activo ? 'No podrá iniciar sesión hasta que lo reactives.' : 'Podrá volver a iniciar sesión.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(usuario.activo ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await usuariosService.actualizar(
        id: usuario.id,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        email: usuario.email,
        telefono: usuario.telefono,
        activo: !usuario.activo,
        rol: usuario.rol,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario ${usuario.nombreCompleto} ${usuario.activo ? 'desactivado' : 'activado'}.')),
      );
      await _cargar();
    } on SesionExpiradaException {
      if (!mounted) return;
      setState(() => sesionExpirada = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      titulo: 'Usuarios de la Empresa',
      embedded: widget.embedded,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (sesionExpirada) {
      return SesionExpiradaView(onReintentar: _cargar);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: exportando ? null : _exportarPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Exportar a PDF'),
              ),
              OutlinedButton.icon(
                onPressed: exportando ? null : _exportarExcel,
                icon: const Icon(Icons.table_view_outlined, size: 18),
                label: const Text('Exportar a Excel'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: buscarController,
            onChanged: (v) => setState(() => busqueda = v),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, email o teléfono',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: busqueda.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        buscarController.clear();
                        setState(() => busqueda = '');
                      },
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
        ),
        if (error.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
          ),
        Expanded(
          child: _filtrados.isEmpty
              ? Center(
                  child: Text(
                    usuarios.isEmpty
                        ? 'Esta empresa todavía no tiene usuarios.'
                        : 'No hay usuarios que coincidan con la búsqueda.',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _filtrados.length,
                    itemBuilder: (context, index) => _tarjetaUsuario(_filtrados[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _tarjetaUsuario(Usuario usuario) {
    final inicial = usuario.nombre.trim().isNotEmpty
        ? usuario.nombre.trim().characters.first.toUpperCase()
        : 'U';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.negro,
              child: Text(
                inicial,
                style: const TextStyle(
                  color: AppTheme.amarilloMarca,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          usuario.nombreCompleto.isEmpty ? 'Usuario' : usuario.nombreCompleto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                      _chip(usuario.rol, AppTheme.bronce),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    usuario.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  if ((usuario.telefono ?? '').isNotEmpty)
                    Text(
                      usuario.telefono!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _chip(
                        usuario.activo ? 'Activo' : 'Inactivo',
                        usuario.activo ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Registro: ${_fechaCorta(usuario.fechaRegistro)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Acciones',
              icon: const Icon(Icons.more_vert),
              onSelected: (opcion) {
                if (opcion == 'editar') {
                  _editar(usuario);
                } else if (opcion == 'estado') {
                  _cambiarActivo(usuario);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'estado',
                  child: Row(
                    children: [
                      Icon(
                        usuario.activo ? Icons.person_off_outlined : Icons.person_add_alt_1_outlined,
                        size: 18,
                        color: usuario.activo ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(usuario.activo ? 'Desactivar' : 'Activar'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Datos capturados en el diálogo de edición de usuario.
class _DatosEdicion {
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String rol;
  final bool activo;

  const _DatosEdicion({
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.rol,
    required this.activo,
  });
}
