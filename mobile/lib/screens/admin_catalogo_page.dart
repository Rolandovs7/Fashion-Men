import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/catalogo_service.dart';
import '../services/sucursales_service.dart';
import '../services/proveedores_service.dart';
import '../services/temporadas_service.dart';
import '../services/colecciones_service.dart';
import '../services/garment_types_service.dart';
import '../services/brands_service.dart';
import '../services/discounts_service.dart';
import '../shared/admin_shell.dart';

// ============================================================
// TRAZABILIDAD MENSTYLE — Ciclo de Vida #2 (Administrar Catálogo)
// CAPA: Flutter | PANTALLA: screens/admin_catalogo_page.dart
// Accesible desde AdminDrawer -> Catálogo.
//
// CU07 Productos      | RF04 | api/routes/products.py       | crear/editar/desactivar
// CU08 Tipo de Prenda  | RF: pendiente de confirmar | api/routes/garment_types.py | crear/editar/desactivar
// CU09 Descuentos      | RF: pendiente de confirmar | api/routes/discounts.py     | crear/editar/desactivar
// CU10 Marcas          | RF: pendiente de confirmar | api/routes/brands.py        | crear/editar/desactivar
// CU11 Tallas          | RF05 | api/routes/sizes.py          | crear/desactivar (sin editar; backend sí soporta PUT)
// CU12 Colores         | RF05 | api/routes/colors.py         | crear/desactivar (sin editar; backend sí soporta PUT)
// CU14 Admin. Catálogo | RF04/RF05/RF07 (agregado de los anteriores)
// CU16 Categorías      | RF05 | api/routes/categories.py     | crear/editar/desactivar
// CU17 Sucursales      | RF03 | api/routes/branches.py       | crear/editar/desactivar
// CU26 Proveedores     | RF06 | api/routes/suppliers.py      | crear/desactivar (sin editar; backend sí soporta PUT)
// CU27 Temporadas      | RF23 | api/routes/seasons.py        | crear/desactivar (sin editar; backend sí soporta PUT)
// CU28 Colecciones     | RF23 | api/routes/collections.py    | crear/desactivar (sin editar; backend sí soporta PUT)
// ============================================================
class AdminCatalogoPage extends StatefulWidget {
  final bool embedded;
  const AdminCatalogoPage({super.key, this.embedded = false});

  @override
  State<AdminCatalogoPage> createState() => _AdminCatalogoPageState();
}

class _AdminCatalogoPageState extends State<AdminCatalogoPage> {
  final catalogoService = CatalogoService();
  final sucursalesService = SucursalesService();
  final proveedoresService = ProveedoresService();
  final temporadasService = TemporadasService();
  final coleccionesService = ColeccionesService();
  final garmentTypesService = GarmentTypesService();
  final brandsService = BrandsService();
  final discountsService = DiscountsService();

  List<Categoria> categorias = [];
  List<Producto> productos = [];
  List<Sucursal> sucursales = [];
  List<Proveedor> proveedores = [];
  List<Temporada> temporadas = [];
  List<Coleccion> colecciones = [];
  List<Talla> tallas = [];
  List<ColorProducto> colores = [];
  List<TipoPrenda> tiposPrenda = [];
  List<Marca> marcas = [];
  List<Descuento> descuentos = [];

  int? productoSeleccionadoParaVariantes;
  List<Variante> variantesDelProducto = [];

  bool cargando = true;
  String mensaje = '';
  String error = '';

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() => cargando = true);
    try {
      final resultados = await Future.wait([
        catalogoService.listarCategorias(soloActivos: false),
        catalogoService.listarProductos(),
        sucursalesService.listar(soloActivos: false),
        proveedoresService.listar(),
        temporadasService.listar(),
        coleccionesService.listar(),
        catalogoService.listarTallas(),
        catalogoService.listarColores(),
        garmentTypesService.listar(),
        brandsService.listar(),
        discountsService.listar(),
      ]);

      setState(() {
        categorias = resultados[0] as List<Categoria>;
        productos = resultados[1] as List<Producto>;
        sucursales = resultados[2] as List<Sucursal>;
        proveedores = resultados[3] as List<Proveedor>;
        temporadas = resultados[4] as List<Temporada>;
        colecciones = resultados[5] as List<Coleccion>;
        tallas = resultados[6] as List<Talla>;
        colores = resultados[7] as List<ColorProducto>;
        tiposPrenda = resultados[8] as List<TipoPrenda>;
        marcas = resultados[9] as List<Marca>;
        descuentos = resultados[10] as List<Descuento>;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudo cargar la información del catálogo.';
        cargando = false;
      });
    }
  }

  void _mostrarMensaje(String texto) {
    setState(() {
      mensaje = texto;
      error = '';
    });
  }

  void _mostrarError(Object e) {
    setState(() {
      error = e.toString().replaceFirst('Exception: ', '');
      mensaje = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 12,
      child: AdminScaffold(
        titulo: 'Gestión de Catálogo',
        embedded: widget.embedded,
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Categorías'),
            Tab(text: 'Productos'),
            Tab(text: 'Variantes'),
            Tab(text: 'Tallas'),
            Tab(text: 'Colores'),
            Tab(text: 'Tipo de Prenda'),
            Tab(text: 'Marcas'),
            Tab(text: 'Descuentos'),
            Tab(text: 'Sucursales'),
            Tab(text: 'Proveedores'),
            Tab(text: 'Temporadas'),
            Tab(text: 'Colecciones'),
          ],
        ),
        body: cargando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (mensaje.isNotEmpty) _banner(mensaje, Colors.green),
                  if (error.isNotEmpty) _banner(error, Colors.red),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _tabCategorias(),
                        _tabProductos(),
                        _tabVariantes(),
                        _tabTallas(),
                        _tabColores(),
                        _tabTiposPrenda(),
                        _tabMarcas(),
                        _tabDescuentos(),
                        _tabSucursales(),
                        _tabProveedores(),
                        _tabTemporadas(),
                        _tabColecciones(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _banner(String texto, Color color) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );

  // ============== CATEGORÍAS ==============
  Widget _tabCategorias() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nueva categoría', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    try {
                      await catalogoService.crearCategoria(
                        nombreCtrl.text.trim(),
                        descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      );
                      _mostrarMensaje('Categoría creada correctamente.');
                      _cargarTodo();
                    } catch (e) {
                      _mostrarError(e);
                    }
                  },
                  child: const Text('Crear categoría'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...categorias.map(
          (c) => Card(
            child: ListTile(
              title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(c.descripcion?.isNotEmpty == true ? c.descripcion! : 'Sin descripción'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editarCategoria(c),
                  ),
                  if (c.activo)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        try {
                          await catalogoService.eliminarCategoria(c.id);
                          _mostrarMensaje('Categoría desactivada.');
                          _cargarTodo();
                        } catch (e) {
                          _mostrarError(e);
                        }
                      },
                    )
                  else
                    const Chip(label: Text('Inactiva'), visualDensity: VisualDensity.compact),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============== PRODUCTOS ==============
  // [Rediseño 2.7] Formulario de alta + buscador + filtro por
  // categoría (chips) + GridView de productos en cards con stock
  // total (suma de variantes) y acciones editar/desactivar.
  Widget _tabProductos() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    int? categoriaId;
    int? proveedorId;
    int? temporadaId;
    int? coleccionId;
    String busqueda = '';
    int? categoriaFiltro;

    return StatefulBuilder(
      builder: (context, setLocalState) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nuevo producto', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: precioCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Precio (Bs)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: categoriaId,
                    decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                    items: categorias
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
                        .toList(),
                    onChanged: (v) => setLocalState(() => categoriaId = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: proveedorId,
                    decoration: const InputDecoration(labelText: 'Proveedor (opcional)', border: OutlineInputBorder()),
                    items: proveedores
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)))
                        .toList(),
                    onChanged: (v) => setLocalState(() => proveedorId = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: temporadaId,
                    decoration: const InputDecoration(labelText: 'Temporada (opcional)', border: OutlineInputBorder()),
                    items: temporadas
                        .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre)))
                        .toList(),
                    onChanged: (v) => setLocalState(() => temporadaId = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: coleccionId,
                    decoration: const InputDecoration(labelText: 'Colección (opcional)', border: OutlineInputBorder()),
                    items: colecciones
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
                        .toList(),
                    onChanged: (v) => setLocalState(() => coleccionId = v),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () async {
                      final precio = double.tryParse(precioCtrl.text.trim());
                      if (nombreCtrl.text.trim().isEmpty || categoriaId == null || precio == null || precio <= 0) {
                        _mostrarError(Exception('Completa nombre, categoría y un precio válido.'));
                        return;
                      }
                      try {
                        await catalogoService.crearProducto(
                          nombre: nombreCtrl.text.trim(),
                          descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          precio: precio,
                          categoriaId: categoriaId!,
                          proveedorId: proveedorId,
                          temporadaId: temporadaId,
                          coleccionId: coleccionId,
                        );
                        _mostrarMensaje('Producto creado correctamente.');
                        _cargarTodo();
                      } catch (e) {
                        _mostrarError(e);
                      }
                    },
                    child: const Text('Crear producto'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // [Rediseño 2.7] Buscador por nombre
          TextField(
            onChanged: (v) => setLocalState(() => busqueda = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar producto por nombre...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          // [Rediseño 2.7] Filtro por categoría (chips)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: categoriaFiltro == null,
                  onSelected: (_) => setLocalState(() => categoriaFiltro = null),
                ),
                const SizedBox(width: 8),
                for (final c in categorias) ...[
                  ChoiceChip(
                    label: Text(c.nombre),
                    selected: categoriaFiltro == c.id,
                    onSelected: (_) => setLocalState(() => categoriaFiltro = c.id),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // [Rediseño 2.7] GridView de productos en cards
          _GrillaProductos(
            productos: productos
                .where((p) =>
                    (categoriaFiltro == null || p.categoriaId == categoriaFiltro) &&
                    (busqueda.isEmpty || p.nombre.toLowerCase().contains(busqueda)))
                .toList(),
            nombresCategoria: {
              for (final c in categorias) c.id: c.nombre,
            },
            onEditar: _editarProducto,
            onDesactivar: (p) async {
              try {
                await catalogoService.eliminarProducto(p.id);
                _mostrarMensaje('Producto desactivado.');
                _cargarTodo();
              } catch (e) {
                _mostrarError(e);
              }
            },
          ),
        ],
      ),
    );
  }

  // ============== VARIANTES ==============
  Widget _tabVariantes() {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        int? tallaId;
        int? colorId;

        Future<void> cargarVariantes(int productoId) async {
          final vars = await catalogoService.listarVariantesPorProducto(productoId);
          setLocalState(() => variantesDelProducto = vars);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              initialValue: productoSeleccionadoParaVariantes,
              decoration: const InputDecoration(labelText: 'Producto', border: OutlineInputBorder()),
              items: productos.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre))).toList(),
              onChanged: (v) async {
                setLocalState(() => productoSeleccionadoParaVariantes = v);
                if (v != null) await cargarVariantes(v);
              },
            ),
            if (productoSeleccionadoParaVariantes != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Nueva variante', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: tallaId,
                        decoration: const InputDecoration(labelText: 'Talla', border: OutlineInputBorder()),
                        items: tallas.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre))).toList(),
                        onChanged: (v) => setLocalState(() => tallaId = v),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: colorId,
                        decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                        items: colores.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                        onChanged: (v) => setLocalState(() => colorId = v),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () async {
                          if (tallaId == null || colorId == null) return;
                          try {
                            await catalogoService.crearVariante(
                              productoId: productoSeleccionadoParaVariantes!,
                              tallaId: tallaId!,
                              colorId: colorId!,
                            );
                            _mostrarMensaje('Variante creada correctamente.');
                            await cargarVariantes(productoSeleccionadoParaVariantes!);
                          } catch (e) {
                            _mostrarError(e);
                          }
                        },
                        child: const Text('Agregar variante'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...variantesDelProducto.map(
                (v) => Card(
                  child: ListTile(
                    title: Text('${v.tallaNombre} · ${v.colorNombre}'),
                    subtitle: Text('Stock disponible: ${v.stockDisponible}'),
                    trailing: Chip(
                      label: Text(v.activo ? 'Activa' : 'Inactiva'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ),
              if (variantesDelProducto.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(child: Text('Este producto aún no tiene variantes.', style: TextStyle(color: Colors.grey))),
                ),
            ],
          ],
        );
      },
    );
  }

  // ============== SUCURSALES ==============
  Widget _tabSucursales() {
    final nombreCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();
    final ciudadCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nueva sucursal', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: direccionCtrl, decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: ciudadCtrl, decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono (opcional)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty || direccionCtrl.text.trim().isEmpty || ciudadCtrl.text.trim().isEmpty) {
                      _mostrarError(Exception('Completa nombre, dirección y ciudad.'));
                      return;
                    }
                    try {
                      await sucursalesService.crear(
                        nombre: nombreCtrl.text.trim(),
                        direccion: direccionCtrl.text.trim(),
                        ciudad: ciudadCtrl.text.trim(),
                        telefono: telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                      );
                      _mostrarMensaje('Sucursal creada correctamente.');
                      _cargarTodo();
                    } catch (e) {
                      _mostrarError(e);
                    }
                  },
                  child: const Text('Crear sucursal'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...sucursales.map(
          (s) => Card(
            child: ListTile(
              title: Text(s.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${s.ciudad} · ${s.direccion}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editarSucursal(s),
                  ),
                  if (s.activo)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        try {
                          await sucursalesService.eliminar(s.id);
                          _mostrarMensaje('Sucursal desactivada.');
                          _cargarTodo();
                        } catch (e) {
                          _mostrarError(e);
                        }
                      },
                    )
                  else
                    const Chip(label: Text('Inactiva'), visualDensity: VisualDensity.compact),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============== PROVEEDORES ==============
  Widget _tabProveedores() {
    final nombreCtrl = TextEditingController();
    final contactoCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nuevo proveedor', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre / Razón social', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: contactoCtrl, decoration: const InputDecoration(labelText: 'Contacto (opcional)', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono (opcional)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    try {
                      await proveedoresService.crear(
                        nombre: nombreCtrl.text.trim(),
                        contacto: contactoCtrl.text.trim().isEmpty ? null : contactoCtrl.text.trim(),
                        telefono: telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                      );
                      _mostrarMensaje('Proveedor creado correctamente.');
                      _cargarTodo();
                    } catch (e) {
                      _mostrarError(e);
                    }
                  },
                  child: const Text('Crear proveedor'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...proveedores.map(
          (p) => Card(
            child: ListTile(
              title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(p.contacto ?? p.telefono ?? 'Sin contacto registrado'),
              trailing: p.activo
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        try {
                          await proveedoresService.eliminar(p.id);
                          _mostrarMensaje('Proveedor desactivado.');
                          _cargarTodo();
                        } catch (e) {
                          _mostrarError(e);
                        }
                      },
                    )
                  : const Chip(label: Text('Inactivo'), visualDensity: VisualDensity.compact),
            ),
          ),
        ),
      ],
    );
  }

  // ============== TEMPORADAS ==============
  Widget _tabTemporadas() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nueva temporada', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej. Otoño-Invierno 2026)', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    try {
                      await temporadasService.crear(
                        nombre: nombreCtrl.text.trim(),
                        descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      );
                      _mostrarMensaje('Temporada creada correctamente.');
                      _cargarTodo();
                    } catch (e) {
                      _mostrarError(e);
                    }
                  },
                  child: const Text('Crear temporada'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...temporadas.map(
          (t) => Card(
            child: ListTile(
              title: Text(t.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(t.descripcion?.isNotEmpty == true ? t.descripcion! : 'Sin descripción'),
              trailing: t.activo
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        try {
                          await temporadasService.eliminar(t.id);
                          _mostrarMensaje('Temporada desactivada.');
                          _cargarTodo();
                        } catch (e) {
                          _mostrarError(e);
                        }
                      },
                    )
                  : const Chip(label: Text('Inactiva'), visualDensity: VisualDensity.compact),
            ),
          ),
        ),
      ],
    );
  }

  // ============== COLECCIONES ==============
  Widget _tabColecciones() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nueva colección', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej. Verano Urbano)', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    try {
                      await coleccionesService.crear(
                        nombre: nombreCtrl.text.trim(),
                        descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      );
                      _mostrarMensaje('Colección creada correctamente.');
                      _cargarTodo();
                    } catch (e) {
                      _mostrarError(e);
                    }
                  },
                  child: const Text('Crear colección'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...colecciones.map(
          (c) => Card(
            child: ListTile(
              title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(c.descripcion?.isNotEmpty == true ? c.descripcion! : 'Sin descripción'),
              trailing: c.activo
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        try {
                          await coleccionesService.eliminar(c.id);
                          _mostrarMensaje('Colección desactivada.');
                          _cargarTodo();
                        } catch (e) {
                          _mostrarError(e);
                        }
                      },
                    )
                  : const Chip(label: Text('Inactiva'), visualDensity: VisualDensity.compact),
            ),
          ),
        ),
      ],
    );
  }

  // ============== TALLAS ==============
  Widget _tabTallas() {
    final nombreCtrl = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nueva talla', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej. XL)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    try {
                      await catalogoService.crearTalla(nombreCtrl.text.trim());
                      _mostrarMensaje('Talla creada correctamente.');
                      _cargarTodo();
                    } catch (e) {
                      _mostrarError(e);
                    }
                  },
                  child: const Text('Crear talla'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...tallas.map(
          (t) => Card(
            child: ListTile(
              title: Text(t.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  try {
                    await catalogoService.eliminarTalla(t.id);
                    _mostrarMensaje('Talla desactivada.');
                    _cargarTodo();
                  } catch (e) {
                    _mostrarError(e);
                  }
                },
              ),
            ),
          ),
        ),
        if (tallas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: Text('No hay tallas registradas.', style: TextStyle(color: Colors.grey))),
          ),
      ],
    );
  }

  // ============== COLORES ==============
  Widget _tabColores() {
    final nombreCtrl = TextEditingController();
    final hexCtrl = TextEditingController(text: '#000000');
    String hex = '#000000';

    return StatefulBuilder(
      builder: (context, setLocalState) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nuevo color', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej. Azul marino)', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(
                    controller: hexCtrl,
                    decoration: const InputDecoration(labelText: 'Código hex (ej. #1E3A8A)', border: OutlineInputBorder()),
                    onChanged: (v) => hex = v,
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () async {
                      if (nombreCtrl.text.trim().isEmpty) return;
                      try {
                        await catalogoService.crearColor(nombreCtrl.text.trim(), hex.trim().isEmpty ? null : hex.trim());
                        _mostrarMensaje('Color creado correctamente.');
                        _cargarTodo();
                      } catch (e) {
                        _mostrarError(e);
                      }
                    },
                    child: const Text('Crear color'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...colores.map(
            (c) => Card(
              child: ListTile(
                leading: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _colorDesdeHex(c.codigoHex),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    try {
                      await catalogoService.eliminarColor(c.id);
                      _mostrarMensaje('Color desactivado.');
                      _cargarTodo();
                    } catch (e) {
                      _mostrarError(e);
                    }
                  },
                ),
              ),
            ),
          ),
          if (colores.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(child: Text('No hay colores registrados.', style: TextStyle(color: Colors.grey))),
            ),
        ],
      ),
    );
  }

  Color _colorDesdeHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey.shade300;
    var codigo = hex.replaceAll('#', '');
    if (codigo.length == 6) codigo = 'FF$codigo';
    try {
      return Color(int.parse(codigo, radix: 16));
    } catch (_) {
      return Colors.grey.shade300;
    }
  }

  // ============== DIÁLOGOS DE EDICIÓN ==============
  Future<void> _editarCategoria(Categoria categoria) async {
    final nombreCtrl = TextEditingController(text: categoria.nombre);
    final descCtrl = TextEditingController(text: categoria.descripcion ?? '');

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Editar categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar cambios')),
          ],
        ),
      ),
    );

    if (guardar != true) return;

    try {
      await catalogoService.actualizarCategoria(
        categoria.id, nombreCtrl.text.trim(),
        descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      );
      _mostrarMensaje('Categoría actualizada correctamente.');
      _cargarTodo();
    } catch (e) {
      _mostrarError(e);
    }
  }

  Future<void> _editarProducto(Producto producto) async {
    final nombreCtrl = TextEditingController(text: producto.nombre);
    final descCtrl = TextEditingController(text: producto.descripcion ?? '');
    final precioCtrl = TextEditingController(text: producto.precio.toString());
    int? categoriaId = producto.categoriaId;

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (context, setModalState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Editar producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: precioCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio (Bs)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: categoriaId,
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                  items: categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                  onChanged: (v) => setModalState(() => categoriaId = v),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar cambios')),
              ],
            ),
          ),
        ),
      ),
    );

    if (guardar != true) return;

    final precio = double.tryParse(precioCtrl.text.trim());
    if (precio == null || categoriaId == null) {
      _mostrarError(Exception('Precio o categoría inválidos.'));
      return;
    }

    try {
      await catalogoService.actualizarProducto(
        id: producto.id,
        nombre: nombreCtrl.text.trim(),
        descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        precio: precio,
        categoriaId: categoriaId!,
        proveedorId: producto.proveedorId,
        temporadaId: producto.temporadaId,
        coleccionId: producto.coleccionId,
      );
      _mostrarMensaje('Producto actualizado correctamente.');
      _cargarTodo();
    } catch (e) {
      _mostrarError(e);
    }
  }

  Future<void> _editarSucursal(Sucursal sucursal) async {
    final nombreCtrl = TextEditingController(text: sucursal.nombre);
    final direccionCtrl = TextEditingController(text: sucursal.direccion);
    final ciudadCtrl = TextEditingController(text: sucursal.ciudad);
    final telefonoCtrl = TextEditingController(text: sucursal.telefono ?? '');

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Editar sucursal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: direccionCtrl, decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: ciudadCtrl, decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar cambios')),
            ],
          ),
        ),
      ),
    );

    if (guardar != true) return;

    try {
      await sucursalesService.actualizar(
        id: sucursal.id,
        nombre: nombreCtrl.text.trim(),
        direccion: direccionCtrl.text.trim(),
        ciudad: ciudadCtrl.text.trim(),
        telefono: telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
      );
      _mostrarMensaje('Sucursal actualizada correctamente.');
      _cargarTodo();
    } catch (e) {
      _mostrarError(e);
    }
  }

  // ============================================================
  // CU08 - Gestión de Tipo de Prenda
  // RF: pendiente de confirmar según matriz oficial.
  // Consume los endpoints existentes de /api/tipos-prenda
  // (GET listar, POST crear, PUT editar, DELETE desactivar).
  // ============================================================
  Widget _tabTiposPrenda() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nuevo tipo de prenda', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej. Camisa formal)', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    try {
                      // CU08 / POST /api/tipos-prenda
                      await garmentTypesService.crear(
                        nombreCtrl.text.trim(),
                        descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      );
                      _mostrarMensaje('Tipo de prenda creado correctamente.');
                      _cargarTodo();
                    } catch (e) {
                      _mostrarError(e);
                    }
                  },
                  child: const Text('Crear tipo de prenda'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...tiposPrenda.map(
          (t) => Card(
            child: ListTile(
              title: Text(t.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(t.descripcion?.isNotEmpty == true ? t.descripcion! : 'Sin descripción'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editarTipoPrenda(t),
                  ),
                  if (t.activo)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmarEliminarTipoPrenda(t),
                    )
                  else
                    const Chip(label: Text('Inactivo'), visualDensity: VisualDensity.compact),
                ],
              ),
            ),
          ),
        ),
        if (tiposPrenda.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: Text('No hay tipos de prenda registrados.', style: TextStyle(color: Colors.grey))),
          ),
      ],
    );
  }

  // CU08 / PUT /api/tipos-prenda/{id} - edita nombre/descripción
  Future<void> _editarTipoPrenda(TipoPrenda tipo) async {
    final nombreCtrl = TextEditingController(text: tipo.nombre);
    final descCtrl = TextEditingController(text: tipo.descripcion ?? '');

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Editar tipo de prenda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar cambios')),
          ],
        ),
      ),
    );

    if (guardar != true) return;

    try {
      await garmentTypesService.actualizar(
        tipo.id,
        nombre: nombreCtrl.text.trim(),
        descripcion: descCtrl.text.trim(),
      );
      _mostrarMensaje('Tipo de prenda actualizado correctamente.');
      _cargarTodo();
    } catch (e) {
      _mostrarError(e);
    }
  }

  // CU08 / DELETE /api/tipos-prenda/{id} - con confirmación previa
  Future<void> _confirmarEliminarTipoPrenda(TipoPrenda tipo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Desactivar el tipo de prenda "${tipo.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, desactivar')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await garmentTypesService.eliminar(tipo.id);
      _mostrarMensaje('Tipo de prenda desactivado.');
      _cargarTodo();
    } catch (e) {
      _mostrarError(e);
    }
  }

  // ============================================================
  // CU10 - Gestión de Marcas
  // RF: pendiente de confirmar según matriz oficial.
  // Consume los endpoints existentes de /api/marcas
  // (GET listar, POST crear, PUT editar, DELETE desactivar).
  // ============================================================
  Widget _tabMarcas() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Nueva marca', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej. Northline)', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    try {
                      // CU10 / POST /api/marcas
                      await brandsService.crear(
                        nombreCtrl.text.trim(),
                        descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      );
                      _mostrarMensaje('Marca creada correctamente.');
                      _cargarTodo();
                    } catch (e) {
                      _mostrarError(e);
                    }
                  },
                  child: const Text('Crear marca'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...marcas.map(
          (m) => Card(
            child: ListTile(
              title: Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(m.descripcion?.isNotEmpty == true ? m.descripcion! : 'Sin descripción'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editarMarca(m),
                  ),
                  if (m.activo)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmarEliminarMarca(m),
                    )
                  else
                    const Chip(label: Text('Inactiva'), visualDensity: VisualDensity.compact),
                ],
              ),
            ),
          ),
        ),
        if (marcas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: Text('No hay marcas registradas.', style: TextStyle(color: Colors.grey))),
          ),
      ],
    );
  }

  // CU10 / PUT /api/marcas/{id} - edita nombre/descripción
  Future<void> _editarMarca(Marca marca) async {
    final nombreCtrl = TextEditingController(text: marca.nombre);
    final descCtrl = TextEditingController(text: marca.descripcion ?? '');

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Editar marca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar cambios')),
          ],
        ),
      ),
    );

    if (guardar != true) return;

    try {
      await brandsService.actualizar(
        marca.id,
        nombre: nombreCtrl.text.trim(),
        descripcion: descCtrl.text.trim(),
      );
      _mostrarMensaje('Marca actualizada correctamente.');
      _cargarTodo();
    } catch (e) {
      _mostrarError(e);
    }
  }

  // CU10 / DELETE /api/marcas/{id} - con confirmación previa
  Future<void> _confirmarEliminarMarca(Marca marca) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Desactivar la marca "${marca.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, desactivar')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await brandsService.eliminar(marca.id);
      _mostrarMensaje('Marca desactivada.');
      _cargarTodo();
    } catch (e) {
      _mostrarError(e);
    }
  }

  // ============================================================
  // CU09 - Gestión de Descuentos
  // RF: pendiente de confirmar según matriz oficial.
  // Consume los endpoints existentes de /api/descuentos
  // (GET listar, POST crear, PUT editar, DELETE desactivar).
  // ============================================================
  Widget _tabDescuentos() {
    final nombreCtrl = TextEditingController();
    final porcentajeCtrl = TextEditingController();
    final fechaInicioCtrl = TextEditingController();
    final fechaFinCtrl = TextEditingController();

    Future<void> elegirFecha(TextEditingController controller) async {
      final fecha = await showDatePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        initialDate: DateTime.now(),
      );
      if (fecha != null) {
        controller.text = fecha.toIso8601String().substring(0, 10);
      }
    }

    return StatefulBuilder(
      builder: (context, setLocalState) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nuevo descuento', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej. Black Friday)', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                    controller: porcentajeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Porcentaje (1-100)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fechaInicioCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Fecha inicio', border: OutlineInputBorder(), isDense: true),
                          onTap: () async {
                            await elegirFecha(fechaInicioCtrl);
                            setLocalState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: fechaFinCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Fecha fin', border: OutlineInputBorder(), isDense: true),
                          onTap: () async {
                            await elegirFecha(fechaFinCtrl);
                            setLocalState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () async {
                      final porcentaje = double.tryParse(porcentajeCtrl.text.trim());
                      if (nombreCtrl.text.trim().isEmpty || porcentaje == null || porcentaje <= 0 || porcentaje > 100) {
                        _mostrarError(Exception('Completa el nombre y un porcentaje válido (1-100).'));
                        return;
                      }
                      try {
                        // CU09 / POST /api/descuentos
                        await discountsService.crear(
                          nombre: nombreCtrl.text.trim(),
                          porcentaje: porcentaje,
                          fechaInicio: fechaInicioCtrl.text.trim().isEmpty ? null : fechaInicioCtrl.text.trim(),
                          fechaFin: fechaFinCtrl.text.trim().isEmpty ? null : fechaFinCtrl.text.trim(),
                        );
                        _mostrarMensaje('Descuento creado correctamente.');
                        _cargarTodo();
                      } catch (e) {
                        _mostrarError(e);
                      }
                    },
                    child: const Text('Crear descuento'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...descuentos.map(
            (d) => Card(
              child: ListTile(
                title: Text(d.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${d.porcentaje}% · ${d.fechaInicio ?? "sin inicio"} → ${d.fechaFin ?? "sin fin"}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editarDescuento(d),
                    ),
                    if (d.activo)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmarEliminarDescuento(d),
                      )
                    else
                      const Chip(label: Text('Inactivo'), visualDensity: VisualDensity.compact),
                  ],
                ),
              ),
            ),
          ),
          if (descuentos.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(child: Text('No hay descuentos registrados.', style: TextStyle(color: Colors.grey))),
            ),
        ],
      ),
    );
  }

  // CU09 / PUT /api/descuentos/{id} - edita nombre/porcentaje/vigencia
  Future<void> _editarDescuento(Descuento descuento) async {
    final nombreCtrl = TextEditingController(text: descuento.nombre);
    final porcentajeCtrl = TextEditingController(text: descuento.porcentaje.toString());
    final fechaInicioCtrl = TextEditingController(text: descuento.fechaInicio ?? '');
    final fechaFinCtrl = TextEditingController(text: descuento.fechaFin ?? '');

    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Editar descuento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(
                controller: porcentajeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Porcentaje (1-100)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fechaInicioCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Fecha inicio', border: OutlineInputBorder(), isDense: true),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (fecha != null) setModalState(() => fechaInicioCtrl.text = fecha.toIso8601String().substring(0, 10));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fechaFinCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Fecha fin', border: OutlineInputBorder(), isDense: true),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (fecha != null) setModalState(() => fechaFinCtrl.text = fecha.toIso8601String().substring(0, 10));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar cambios')),
            ],
          ),
        ),
      ),
    );

    if (guardar != true) return;

    final porcentaje = double.tryParse(porcentajeCtrl.text.trim());
    if (porcentaje == null || porcentaje <= 0 || porcentaje > 100) {
      _mostrarError(Exception('Porcentaje inválido.'));
      return;
    }

    try {
      await discountsService.actualizar(
        descuento.id,
        nombre: nombreCtrl.text.trim(),
        porcentaje: porcentaje,
        fechaInicio: fechaInicioCtrl.text.trim().isEmpty ? null : fechaInicioCtrl.text.trim(),
        fechaFin: fechaFinCtrl.text.trim().isEmpty ? null : fechaFinCtrl.text.trim(),
      );
      _mostrarMensaje('Descuento actualizado correctamente.');
      _cargarTodo();
    } catch (e) {
      _mostrarError(e);
    }
  }

  // CU09 / DELETE /api/descuentos/{id} - con confirmación previa
  Future<void> _confirmarEliminarDescuento(Descuento descuento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Desactivar el descuento "${descuento.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, desactivar')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await discountsService.eliminar(descuento.id);
      _mostrarMensaje('Descuento desactivado.');
      _cargarTodo();
    } catch (e) {
      _mostrarError(e);
    }
  }
}

/// ============================================================
/// [Rediseño 2.7] Grilla de productos en cards.
/// Muestra imagen (con fallback), nombre, categoría, precio y
/// stock total (suma de `stock_disponible` de las variantes,
/// cargado de forma diferida por producto). Al cambiar la lista
/// filtrada, `didUpdateWidget` carga solo los productos nuevos.
/// ============================================================
class _GrillaProductos extends StatefulWidget {
  final List<Producto> productos;
  final Map<int, String> nombresCategoria;
  final void Function(Producto) onEditar;
  final void Function(Producto) onDesactivar;

  const _GrillaProductos({
    required this.productos,
    required this.nombresCategoria,
    required this.onEditar,
    required this.onDesactivar,
  });

  @override
  State<_GrillaProductos> createState() => _GrillaProductosState();
}

class _GrillaProductosState extends State<_GrillaProductos> {
  final CatalogoService _catalogoService = CatalogoService();

  /// Stock total por producto_id (suma de variantes).
  final Map<int, int> _stocks = {};

  @override
  void initState() {
    super.initState();
    _cargarStocks(widget.productos);
  }

  @override
  void didUpdateWidget(covariant _GrillaProductos oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nuevos = widget.productos.where((p) => !_stocks.containsKey(p.id)).toList();
    if (nuevos.isNotEmpty) {
      _cargarStocks(nuevos);
    }
  }

  Future<void> _cargarStocks(List<Producto> productos) async {
    for (final p in productos) {
      // Evita trabajos innecesarios si el widget ya no está montado.
      if (!mounted) return;
      try {
        final variantes = await _catalogoService.listarVariantesPorProducto(p.id);
        if (!mounted) return;
        setState(() {
          _stocks[p.id] = variantes.fold<int>(0, (suma, v) => suma + v.stockDisponible);
        });
      } catch (_) {
        // Sin datos de variantes: se muestra el card sin stock.
        if (!mounted) return;
        setState(() => _stocks[p.id] = 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.productos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('No se encontraron productos.', style: TextStyle(color: Colors.grey))),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.productos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, i) {
        final p = widget.productos[i];
        return _cardProducto(p);
      },
    );
  }

  Widget _cardProducto(Producto p) {
    final categoria = widget.nombresCategoria[p.categoriaId] ?? 'Sin categoría';
    final stock = _stocks[p.id];
    final stockBajo = (stock ?? 0) <= p.stockMinimo;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.activo ? Colors.grey.shade300 : Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen con fallback (inicial del producto sobre negro)
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (p.imagenUrl != null && p.imagenUrl!.isNotEmpty)
                  Image.network(
                    p.imagenUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallbackImagen(p),
                  )
                else
                  _fallbackImagen(p),
                if (!p.activo)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Inactivo',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Datos + acciones
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(categoria, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('Bs ${p.precio.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        stock == null ? Icons.hourglass_empty : (stockBajo ? Icons.error_outline : Icons.inventory_2_outlined),
                        size: 13,
                        color: stock == null ? Colors.grey : (stockBajo ? Colors.orange : Colors.green),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stock == null ? 'Cargando…' : 'Stock: $stock',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: stock == null ? Colors.grey : (stockBajo ? Colors.orange.shade800 : Colors.green.shade700),
                          ),
                        ),
                      ),
                      if (p.activo)
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => widget.onDesactivar(p),
                          ),
                        ),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => widget.onEditar(p),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImagen(Producto p) {
    final inicial = p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?';
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Text(
        inicial,
        style: const TextStyle(
          color: Color(0xFFFFD400),
          fontWeight: FontWeight.w800,
          fontSize: 30,
        ),
      ),
    );
  }
}
