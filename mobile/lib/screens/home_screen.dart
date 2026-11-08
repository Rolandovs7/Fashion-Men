import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/catalogo_service.dart';
import 'catalogo_page.dart';
import 'producto_detalle_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _amarillo = AppTheme.amarilloMarca;
  final _catalogo = CatalogoService();
  List<Categoria> _categorias = [];
  List<Producto> _destacados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await Future.wait([
        _catalogo.listarCategorias(),
        _catalogo.listarProductos(),
      ]);
      final cats = res[0] as List<Categoria>;
      final prods = (res[1] as List<Producto>).where((p) => p.activo).toList();
      if (!mounted) return;
      setState(() {
        _categorias = cats;
        _destacados = prods.take(8).toList();
        _cargando = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[HomeScreen] Error cargando destacados: $e');
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoCatalogo,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _header(),
              const SizedBox(height: 18),
              if (_cargando)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (_categorias.isNotEmpty) ...[
                  _tituloSeccion('Categorías'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categorias.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final c = _categorias[i];
                        return Material(
                          color: AppTheme.negro,
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CatalogoPage(categoriaInicialId: c.id),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: _amarillo.withValues(alpha: 0.5)),
                              ),
                              child: Center(
                                child: Text(
                                  c.nombre,
                                  style: const TextStyle(
                                    color: _amarillo,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                _tituloSeccion('Productos destacados'),
                const SizedBox(height: 10),
                if (_destacados.isEmpty)
                  const Text('No hay productos para mostrar.')
                else
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _destacados.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _ProductoCarouselCard(producto: _destacados[i]),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.negro,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _amarillo,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.checkroom, color: AppTheme.negro, size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MenStyle',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Moda masculina · Tienda y POS',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSeccion(String t) => Text(
        t,
        style: const TextStyle(
          color: AppTheme.negro,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      );
}

class _ProductoCarouselCard extends StatelessWidget {
  final Producto producto;
  const _ProductoCarouselCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.urlCompleta(producto.imagenUrl);
    return SizedBox(
      width: 150,
      child: Card(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProductoDetallePage(productoId: producto.id)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: url == null
                    ? Container(
                        color: AppTheme.negro,
                        child: const Icon(Icons.checkroom, color: Colors.white54, size: 34),
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => Container(
                          color: AppTheme.negro,
                          child: const Icon(Icons.checkroom, color: Colors.white54, size: 34),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bs ${producto.precio.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: AppTheme.negro),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
