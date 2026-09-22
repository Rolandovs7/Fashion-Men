import 'package:flutter/material.dart';

import '../core/config.dart';
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
      setState(() {
        agregando = false;
        mensaje = 'Prenda agregada al carrito.';
      });
    } catch (e) {
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
      appBar: AppBar(title: const Text('Detalle de prenda')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : producto == null
          ? Center(
              child: Text(error.isEmpty ? 'Producto no disponible' : error),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 260,
                      width: double.infinity,
                      child: _ImagenDetalle(
                        rutaRelativa: producto!.imagenUrl,
                        nombre: producto!.nombre,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    producto!.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bs ${producto!.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    producto!.descripcion?.isNotEmpty == true
                        ? producto!.descripcion!
                        : 'Sin descripción disponible para esta prenda.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _abrirVestidorVirtual,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Probar con cámara (AR)'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (variantes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Text(
                        'Este producto aún no tiene tallas ni colores configurados.',
                        style: TextStyle(color: Colors.brown),
                      ),
                    )
                  else ...[
                    const Text(
                      'ELIGE TALLA Y COLOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: variantes.map((v) {
                        final seleccionada = varianteSeleccionada?.id == v.id;
                        final sinStock = v.stockDisponible == 0;
                        return GestureDetector(
                          onTap: sinStock
                              ? null
                              : () => setState(() {
                                  varianteSeleccionada = v;
                                  error = '';
                                  mensaje = '';
                                }),
                          child: Opacity(
                            opacity: sinStock ? 0.4 : 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: seleccionada
                                      ? Colors.black
                                      : Colors.grey.shade300,
                                  width: seleccionada ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _colorDesdeHex(v.colorHex),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${v.tallaNombre} · ${v.colorNombre}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (varianteSeleccionada != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        varianteSeleccionada!.stockDisponible > 0
                            ? '${varianteSeleccionada!.stockDisponible} unidades disponibles'
                            : 'Sin stock para esta combinación',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: varianteSeleccionada!.stockDisponible > 0
                              ? Colors.green.shade700
                              : Colors.red,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Text(
                          'Cantidad',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton.filledTonal(
                          onPressed: cantidad > 1
                              ? () => setState(() => cantidad--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$cantidad',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => setState(() => cantidad++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (mensaje.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        mensaje,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed:
                          (agregando ||
                              variantes.isEmpty ||
                              (varianteSeleccionada?.stockDisponible ?? 0) == 0)
                          ? null
                          : _agregarAlCarrito,
                      child: Text(
                        agregando ? 'Agregando...' : 'Agregar al carrito',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
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
