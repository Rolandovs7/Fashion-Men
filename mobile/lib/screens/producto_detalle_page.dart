import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/catalogo_service.dart';
import '../services/carrito_service.dart';
import '../services/auth_service.dart';
import 'vestidor_virtual_page.dart';

class ProductoDetallePage extends StatefulWidget {
  final int productoId;

  const ProductoDetallePage({super.key, required this.productoId});

  @override
  State<ProductoDetallePage> createState() => _ProductoDetallePageState();
}

class _ProductoDetallePageState extends State<ProductoDetallePage> {
  final catalogoService = CatalogoService();
  final carritoService = CarritoService();

  Producto? producto;
  List<Variante> variantes = [];
  Variante? varianteSeleccionada;
  int cantidad = 1;

  bool cargando = true;
  bool agregando = false;
  String error = '';
  String mensaje = '';

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
        catalogoService.obtenerProducto(widget.productoId),
        catalogoService.listarVariantesPorProducto(widget.productoId),
      ]);

      final prod = resultados[0] as Producto;
      final vars = resultados[1] as List<Variante>;

      setState(() {
        producto = prod;
        variantes = vars;
        varianteSeleccionada =
            vars.where((v) => v.stockDisponible > 0).isNotEmpty
            ? vars.firstWhere((v) => v.stockDisponible > 0)
            : (vars.isNotEmpty ? vars.first : null);
        cantidad = 1;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        error = 'No se pudo cargar el producto.';
        cargando = false;
      });
    }
  }

  Future<void> _agregarAlCarrito() async {
    if (AuthService.instance.token == null) {
      setState(() => error = 'Inicia sesión para agregar al carrito.');
      return;
    }

    if (varianteSeleccionada == null) {
      setState(() => error = 'Selecciona una talla y color disponibles.');
      return;
    }

    if (cantidad < 1 || cantidad > varianteSeleccionada!.stockDisponible) {
      setState(() => error = 'Cantidad inválida para el stock disponible.');
      return;
    }

    setState(() {
      agregando = true;
      error = '';
      mensaje = '';
    });

    try {
      await carritoService.agregarItem(varianteSeleccionada!.id, cantidad);
      if (!mounted) return;
      setState(() {
        agregando = false;
        cantidad = 1;
        mensaje = 'Prenda agregada al carrito.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        agregando = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _abrirVestidorVirtual() {
    final url = AppConfig.urlCompleta(producto?.imagenUrl);
    if (url == null) {
      setState(
        () => error = 'Esta prenda no tiene una imagen disponible para probar.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VestidorVirtualPage(
          imagenPrendaUrl: url,
          nombrePrenda: producto!.nombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoClaro,
      appBar: AppBar(
        backgroundColor: AppTheme.fondoClaro,
        surfaceTintColor: Colors.transparent,
        title: const Text('Detalle de prenda'),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : producto == null
          ? Center(
              child: Text(error.isEmpty ? 'Producto no disponible' : error),
            )
          : _construirDetalle(producto!),
    );
  }

  Widget _construirDetalle(Producto prod) {
    final variante = varianteSeleccionada;
    final sinStock = variante == null || variante.stockDisponible <= 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen principal a todo el ancho, 300 px y recorte cover.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: _ImagenDetalle(
                rutaRelativa: prod.imagenUrl,
                nombre: prod.nombre,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod.nombre,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.15,
                    color: AppTheme.negro,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppTheme.amarilloMarca,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Bs ${prod.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: AppTheme.bronce,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  prod.descripcion?.isNotEmpty == true
                      ? prod.descripcion!
                      : 'Sin descripción disponible para esta prenda.',
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: AppTheme.grisTexto,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _abrirVestidorVirtual,
                    icon: const Icon(Icons.view_in_ar_outlined, size: 20),
                    label: const Text('Probar con cámara (AR)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.negro,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.grey.shade300, height: 1),
                const SizedBox(height: 20),
                if (variantes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: const Text(
                      'Este producto aún no tiene tallas ni colores configurados.',
                      style: TextStyle(
                        color: Colors.brown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else ...[
                  const Text(
                    'Talla y color',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.negro,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: variantes.map((v) {
                      final seleccionada = varianteSeleccionada?.id == v.id;
                      final agotada = v.stockDisponible <= 0;
                      return ChoiceChip(
                        selected: seleccionada,
                        showCheckmark: false,
                        onSelected: agotada
                            ? null
                            : (_) => setState(() {
                                varianteSeleccionada = v;
                                if (cantidad > v.stockDisponible) {
                                  cantidad = v.stockDisponible;
                                }
                                error = '';
                                mensaje = '';
                              }),
                        avatar: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _colorDesdeHex(v.colorHex),
                            border: Border.all(color: Colors.black12),
                          ),
                        ),
                        label: Text(
                          '${v.tallaNombre} · ${v.colorNombre}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: seleccionada
                                ? Colors.white
                                : agotada
                                ? Colors.grey
                                : AppTheme.negro,
                          ),
                        ),
                        selectedColor: AppTheme.negro,
                        backgroundColor: Colors.white,
                        disabledColor: Colors.grey.shade100,
                        side: BorderSide(
                          color: seleccionada
                              ? AppTheme.negro
                              : Colors.grey.shade300,
                          width: seleccionada ? 1.5 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  _StockPill(
                    stock: variante?.stockDisponible ?? 0,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Text(
                        'Cantidad',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppTheme.negro,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: cantidad > 1
                                  ? () => setState(() => cantidad--)
                                  : null,
                              icon: const Icon(Icons.remove, size: 18),
                              visualDensity: VisualDensity.compact,
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '$cantidad',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  (variante != null &&
                                      cantidad < variante.stockDisponible)
                                  ? () => setState(() => cantidad++)
                                  : null,
                              icon: const Icon(Icons.add, size: 18),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                if (mensaje.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _MensajeDetalle(
                    texto: mensaje,
                    color: Colors.green.shade700,
                    icono: Icons.check_circle_outline,
                  ),
                ],
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _MensajeDetalle(
                    texto: error,
                    color: Colors.red,
                    icono: Icons.error_outline,
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: (agregando ||
                            variantes.isEmpty ||
                            sinStock)
                        ? null
                        : _agregarAlCarrito,
                    icon: agregando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.shopping_bag_outlined),
                    label: Text(
                      agregando ? 'Agregando...' : 'Agregar al Carrito',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.negro,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorDesdeHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey.shade300;
    var codigo = hex.replaceAll('#', '');
    if (codigo.length == 6) codigo = 'FF$codigo';
    return Color(int.parse(codigo, radix: 16));
  }
}

class _StockPill extends StatelessWidget {
  final int stock;

  const _StockPill({required this.stock});

  @override
  Widget build(BuildContext context) {
    final disponible = stock > 0;
    final color = disponible ? Colors.green.shade700 : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            disponible
                ? Icons.check_circle_outline
                : Icons.remove_circle_outline,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            disponible
                ? '$stock unidades disponibles'
                : 'Sin stock para esta combinación',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MensajeDetalle extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData icono;

  const _MensajeDetalle({
    required this.texto,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagenDetalle extends StatelessWidget {
  final String? rutaRelativa;
  final String nombre;

  const _ImagenDetalle({required this.rutaRelativa, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.urlCompleta(rutaRelativa);

    if (url == null) return _placeholder();

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.high,
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
          colors: [Color(0xFF171717), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: cargando
            ? const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white54,
                ),
              )
            : const Icon(Icons.checkroom, color: Colors.white54, size: 64),
      ),
    );
  }
}
