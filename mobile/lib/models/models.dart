class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.activo,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
    id: json['id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    activo: json['activo'] ?? true,
  );
}

class Proveedor {
  final int id;
  final String nombre;
  final String? contacto;
  final String? telefono;
  final String? email;
  final String? direccion;
  final bool activo;

  Proveedor({
    required this.id,
    required this.nombre,
    this.contacto,
    this.telefono,
    this.email,
    this.direccion,
    required this.activo,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) => Proveedor(
    id: json['id'],
    nombre: json['nombre'],
    contacto: json['contacto'],
    telefono: json['telefono'],
    email: json['email'],
    direccion: json['direccion'],
    activo: json['activo'] ?? true,
  );
}

class Temporada {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  Temporada({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.activo,
  });

  factory Temporada.fromJson(Map<String, dynamic> json) => Temporada(
    id: json['id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    activo: json['activo'] ?? true,
  );
}

class Coleccion {
  final int id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  Coleccion({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.activo,
  });

  factory Coleccion.fromJson(Map<String, dynamic> json) => Coleccion(
    id: json['id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    activo: json['activo'] ?? true,
  );
}

class Usuario {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final bool activo;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.activo,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'],
    nombre: json['nombre'],
    apellido: json['apellido'],
    email: json['email'],
    activo: json['activo'] ?? true,
    rol: json['rol'] ?? 'cliente',
  );
}

class Permiso {
  final int id;
  final String nombre;
  final String descripcion;
  final bool activo;

  Permiso({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.activo,
  });

  factory Permiso.fromJson(Map<String, dynamic> json) => Permiso(
    id: json['id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'] ?? '',
    activo: json['activo'] ?? true,
  );
}

class Producto {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? imagenUrl;
  final double precio;
  final int categoriaId;
  final int? proveedorId;
  final int? temporadaId;
  final int? coleccionId;
  final bool activo;

  Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imagenUrl,
    required this.precio,
    required this.categoriaId,
    this.proveedorId,
    this.temporadaId,
    this.coleccionId,
    required this.activo,
  });

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
    id: json['id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    imagenUrl: json['imagen_url'],
    precio: (json['precio'] as num).toDouble(),
    categoriaId: json['categoria_id'],
    proveedorId: json['proveedor_id'],
    temporadaId: json['temporada_id'],
    coleccionId: json['coleccion_id'],
    activo: json['activo'] ?? true,
  );
}

class Variante {
  final int id;
  final int productoId;
  final int tallaId;
  final String tallaNombre;
  final int colorId;
  final String colorNombre;
  final String? colorHex;
  final bool activo;
  final int stockDisponible;

  Variante({
    required this.id,
    required this.productoId,
    required this.tallaId,
    required this.tallaNombre,
    required this.colorId,
    required this.colorNombre,
    this.colorHex,
    required this.activo,
    required this.stockDisponible,
  });

  factory Variante.fromJson(Map<String, dynamic> json) => Variante(
    id: json['id'],
    productoId: json['producto_id'],
    tallaId: json['talla_id'],
    tallaNombre: json['talla_nombre'],
    colorId: json['color_id'],
    colorNombre: json['color_nombre'],
    colorHex: json['color_codigo_hex'],
    activo: json['activo'] ?? true,
    stockDisponible: json['stock_disponible'] ?? 0,
  );
}

class Sucursal {
  final int id;
  final String nombre;
  final String direccion;
  final String ciudad;
  final String? telefono;
  final bool activo;

  Sucursal({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.ciudad,
    this.telefono,
    required this.activo,
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) => Sucursal(
    id: json['id'],
    nombre: json['nombre'],
    direccion: json['direccion'],
    ciudad: json['ciudad'],
    telefono: json['telefono'],
    activo: json['activo'] ?? true,
  );
}

class DetalleCarrito {
  final int id;
  final int carritoId;
  final int varianteId;
  final int cantidad;

  DetalleCarrito({
    required this.id,
    required this.carritoId,
    required this.varianteId,
    required this.cantidad,
  });

  factory DetalleCarrito.fromJson(Map<String, dynamic> json) => DetalleCarrito(
    id: json['id'],
    carritoId: json['carrito_id'],
    varianteId: json['variante_id'],
    cantidad: json['cantidad'],
  );
}

class Carrito {
  final int id;
  final int usuarioId;
  final List<DetalleCarrito> detalles;

  Carrito({required this.id, required this.usuarioId, required this.detalles});

  factory Carrito.fromJson(Map<String, dynamic> json) => Carrito(
    id: json['id'],
    usuarioId: json['usuario_id'],
    detalles: (json['detalles'] as List)
        .map((d) => DetalleCarrito.fromJson(d))
        .toList(),
  );
}

class DetallePedido {
  final int id;
  final int pedidoId;
  final int varianteId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetallePedido({
    required this.id,
    required this.pedidoId,
    required this.varianteId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> json) => DetallePedido(
    id: json['id'],
    pedidoId: json['pedido_id'],
    varianteId: json['variante_id'],
    cantidad: json['cantidad'],
    precioUnitario: (json['precio_unitario'] as num).toDouble(),
    subtotal: (json['subtotal'] as num).toDouble(),
  );
}

class Pedido {
  final int id;
  final int usuarioId;
  final String fechaPedido;
  final String estado;
  final double total;
  final List<DetallePedido> detalles;

  Pedido({
    required this.id,
    required this.usuarioId,
    required this.fechaPedido,
    required this.estado,
    required this.total,
    required this.detalles,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
    id: json['id'],
    usuarioId: json['usuario_id'],
    fechaPedido: json['fecha_pedido'],
    estado: json['estado'],
    total: (json['total'] as num).toDouble(),
    detalles: (json['detalles'] as List)
        .map((d) => DetallePedido.fromJson(d))
        .toList(),
  );
}

class DetalleReserva {
  final int id;
  final int reservaId;
  final int varianteId;
  final int cantidad;

  DetalleReserva({
    required this.id,
    required this.reservaId,
    required this.varianteId,
    required this.cantidad,
  });

  factory DetalleReserva.fromJson(Map<String, dynamic> json) => DetalleReserva(
    id: json['id'],
    reservaId: json['reserva_id'],
    varianteId: json['variante_id'],
    cantidad: json['cantidad'],
  );
}

class Reserva {
  final int id;
  final int usuarioId;
  final int sucursalId;
  final String fechaReserva;
  final String estado;
  final String? observaciones;
  final List<DetalleReserva> detalles;

  Reserva({
    required this.id,
    required this.usuarioId,
    required this.sucursalId,
    required this.fechaReserva,
    required this.estado,
    this.observaciones,
    required this.detalles,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
    id: json['id'],
    usuarioId: json['usuario_id'],
    sucursalId: json['sucursal_id'],
    fechaReserva: json['fecha_reserva'],
    estado: json['estado'],
    observaciones: json['observaciones'],
    detalles: (json['detalles'] as List)
        .map((d) => DetalleReserva.fromJson(d))
        .toList(),
  );
}
