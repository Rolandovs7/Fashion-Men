import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';
import 'chat_page.dart';
import '../models/models.dart';
import '../services/catalogo_service.dart';
import 'producto_detalle_page.dart';

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  final catalogoService = CatalogoService();

  List<Producto> productos = [];
  List<Categoria> categorias = [];

  int? categoriaSeleccionada;
  String busqueda = '';

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
      final resultados = await Future.wait([
        catalogoService.listarCategorias(),
        catalogoService.listarProductos(),
      ]);

      setState(() {
        categorias = resultados[0] as List<Categoria>;
        productos = (resultados[1] as List<Producto>)
            .where((p) => p.activo)
            .toList();
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudo cargar el catálogo. Desliza para reintentar.';
        cargando = false;
      });
    }
  }

  List<Producto> get _productosFiltrados {
    return productos.where((p) {
      final coincideCategoria =
          categoriaSeleccionada == null ||
          p.categoriaId == categoriaSeleccionada;
      final coincideBusqueda =
          busqueda.trim().isEmpty ||
          p.nombre.toLowerCase().contains(busqueda.trim().toLowerCase());
      return coincideCategoria && coincideBusqueda;
    }).toList();
  }

  String _nombreCategoria(int categoriaId) {
    final cat = categorias.where((c) => c.id == categoriaId);
    return cat.isEmpty ? 'Sin categoría' : cat.first.nombre;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoCatalogo,
      appBar: AppBar(title: const Text('MENSTYLE')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ChatPage())),
        backgroundColor: AppTheme.negro,
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : error.isNotEmpty
            ? _EstadoVacio(mensaje: error, icono: Icons.error_outline)
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar por nombre...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => busqueda = v),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _ChipCategoria(
                            label: 'Todas',
                            seleccionado: categoriaSeleccionada == null,
                            onTap: () =>
                                setState(() => categoriaSeleccionada = null),
                          ),
                          ...categorias.map(
                            (c) => _ChipCategoria(
                              label: c.nombre,
                              seleccionado: categoriaSeleccionada == c.id,
                              onTap: () =>
                                  setState(() => categoriaSeleccionada = c.id),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  _productosFiltrados.isEmpty
                      ? const SliverFillRemaining(
                          child: _EstadoVacio(
                            mensaje:
                                'No se encontraron prendas con esos filtros.',
                            icono: Icons.checkroom_outlined,
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.68,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final producto = _productosFiltrados[index];
                              return _TarjetaProducto(
                                producto: producto,
                                categoriaNombre: _nombreCategoria(
                                  producto.categoriaId,
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProductoDetallePage(
                                        productoId: producto.id,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }, childCount: _productosFiltrados.length),
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipCategoria({
    required this.label,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: seleccionado ? AppTheme.negro : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: seleccionado ? AppTheme.negro : const Color(0xFFE0E0E0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: seleccionado ? Colors.white : AppTheme.negro,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  final Producto producto;
  final String categoriaNombre;
  final VoidCallback onTap;

  const _TarjetaProducto({
    required this.producto,
    required this.categoriaNombre,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _ImagenProducto(
                rutaRelativa: producto.imagenUrl,
                nombre: producto.nombre,
                iconoFallback: Icons.checkroom,
                tamanioIcono: 36,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoriaNombre.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grisTexto,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: AppTheme.negro,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bs ${producto.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppTheme.negro,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagenProducto extends StatelessWidget {
  final String? rutaRelativa;
  final String nombre;
  final IconData iconoFallback;
  final double tamanioIcono;

  const _ImagenProducto({
    required this.rutaRelativa,
    required this.nombre,
    this.iconoFallback = Icons.checkroom,
    this.tamanioIcono = 40,
  });

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.urlCompleta(rutaRelativa);

    if (url == null) {
      return _placeholder();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _placeholder(cargando: true);
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder({bool cargando = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF262626), Color(0xFF0A0A0A)],
        ),
      ),
      child: Center(
        child: cargando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              )
            : Icon(iconoFallback, color: Colors.white54, size: tamanioIcono),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final String mensaje;
  final IconData icono;

  const _EstadoVacio({required this.mensaje, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
