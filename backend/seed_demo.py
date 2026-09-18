# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU07 - Gestionar Productos
# CU: CU08 - Gestionar Tipo de Prenda
# CU: CU10 - Gestionar Marcas
# CU: CU11 - Gestionar Tallas
# CU: CU12 - Gestionar Colores
# CU: CU13 - Gestionar Imágenes (RF04)
# CU: CU14 - Administrar Catálogo (RF07)
# CU: CU15 - Administrar Inventario (RF21, RF22)
# CU: CU16 - Gestionar Categorías
# CU: CU17 - Gestionar Sucursales (RF03)
# CU: CU26 - Gestionar Proveedores (RF06)
# CU: CU27 - Gestionar Temporadas (RF23)
# CU: CU28 - Gestionar Colecciones (RF23)
# CU: CU29 - Visualizar Dashboard (necesita datos reales)
# CU: CU30 - Generar Reportes (necesita datos reales)
# CU: CU31 - Recibir Recomendaciones IA (necesita historial)
# RF: RF01 - Registrar clientes
# RF: RF03 - Administrar ciudades y sucursales
# RF: RF04 - Gestionar productos de ropa
# RF: RF05 - Gestionar tallas, colores, categorías
# RF: RF06 - Gestionar proveedores
# RF: RF07 - Consultar catálogo
# RF: RF21 - Controlar existencias por sucursal
# RF: RF22 - Registrar movimientos
# RF: RF23 - Gestionar temporadas y colecciones
# ENDPOINT: Script de línea de comandos (python seed_demo.py)
# CAPA: Backend FastAPI (Seed de datos demo)
# IDEMPOTENTE: sí (se puede ejecutar múltiples veces sin duplicar)
# ============================================================
from decimal import Decimal

from app.core.database import SessionLocal
from app.core.security import obtener_password_hash

from app.models.category import Categoria
from app.models.brand import Marca
from app.models.branch import Sucursal
from app.models.supplier import Proveedor
from app.models.season import Temporada
from app.models.collection import Coleccion
from app.models.size import Talla
from app.models.color import Color
from app.models.garment_type import TipoPrenda
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.inventory import Inventario
from app.models.user import Usuario
from app.models.role import Rol


def _get_or_create(db, modelo, defaults=None, **kwargs):
    """Busca por kwargs; si no existe, lo crea con defaults + kwargs."""
    instancia = db.query(modelo).filter_by(**kwargs).first()
    if instancia:
        return instancia, False
    datos = {**(defaults or {}), **kwargs}
    instancia = modelo(**datos)
    db.add(instancia)
    db.flush()
    return instancia, True


def sembrar_roles(db):
    roles = [
        ("cliente", "Cliente de la tienda"),
        ("administrador", "Administrador de la plataforma"),
        ("encargado", "Encargado de sucursal"),
        ("cajero", "Cajero de punto de venta"),
        ("proveedor", "Proveedor de productos"),
    ]
    nuevos = 0
    for nombre, desc in roles:
        _, creado = _get_or_create(
            db, Rol, nombre=nombre, defaults={"descripcion": desc, "activo": True}
        )
        nuevos += int(creado)
    print(f"  Roles nuevos: {nuevos}")


def sembrar_usuarios(db):
    usuarios = [
        ("Rolando", "Velasco", "rolando@gmail.com", "123456", "administrador"),
        ("Juan", "Pérez", "juan@gmail.com", "123456", "cliente"),
        ("María", "García", "maria@gmail.com", "123456", "cliente"),
    ]
    nuevos = 0
    for nombre, apellido, email, password, rol in usuarios:
        _, creado = _get_or_create(
            db,
            Usuario,
            email=email,
            defaults={
                "nombre": nombre,
                "apellido": apellido,
                "password_hash": obtener_password_hash(password),
                "rol": rol,
                "activo": True,
            },
        )
        nuevos += int(creado)
    print(f"  Usuarios nuevos: {nuevos}")


def sembrar_sucursales(db):
    sucursales = [
        ("MenStyle La Paz Centro", "Av. 16 de Julio #1234", "La Paz", "2-2345678"),
        ("MenStyle Santa Cruz", "Av. Monseñor Rivero #567", "Santa Cruz", "3-3456789"),
        ("MenStyle Cochabamba", "Av. Heroínas #890", "Cochabamba", "4-4567890"),
    ]
    nuevos = 0
    for nombre, direccion, ciudad, telefono in sucursales:
        _, creado = _get_or_create(
            db,
            Sucursal,
            nombre=nombre,
            defaults={
                "direccion": direccion,
                "ciudad": ciudad,
                "telefono": telefono,
                "activo": True,
            },
        )
        nuevos += int(creado)
    print(f"  Sucursales nuevas: {nuevos}")


def sembrar_categorias(db):
    categorias = [
        ("Camisas", "Camisas formales y casuales"),
        ("Pantalones", "Pantalones de vestir y jeans"),
        ("Zapatos", "Calzado formal y casual"),
        ("Accesorios", "Cinturones, corbatas, etc."),
        ("Chaquetas", "Chaquetas y abrigos"),
        ("Poleras", "Poleras y camisetas"),
        ("Trajes", "Trajes completos"),
        ("Ropa Deportiva", "Ropa para actividad física"),
    ]
    nuevos = 0
    for nombre, desc in categorias:
        _, creado = _get_or_create(
            db, Categoria, nombre=nombre, defaults={"descripcion": desc, "activo": True}
        )
        nuevos += int(creado)
    print(f"  Categorías nuevas: {nuevos}")


def sembrar_marcas(db):
    marcas = [
        ("Zara", "Moda española contemporánea"),
        ("H&M", "Moda sueca accesible"),
        ("Levi's", "Jeans y ropa casual"),
        ("Nike", "Ropa y calzado deportivo"),
        ("Adidas", "Ropa y calzado deportivo"),
        ("Tommy Hilfiger", "Moda americana premium"),
    ]
    nuevos = 0
    for nombre, desc in marcas:
        _, creado = _get_or_create(
            db, Marca, nombre=nombre, defaults={"descripcion": desc, "activo": True}
        )
        nuevos += int(creado)
    print(f"  Marcas nuevas: {nuevos}")


def sembrar_proveedores(db):
    proveedores = [
        ("Textiles Bolivia S.A.", "Carlos Rojas", "2-2345678", "ventas@textilesbolivia.com"),
        ("Importadora Andina", "Ana Gutiérrez", "3-3456789", "contacto@andina.com"),
        ("Moda Import SRL", "Luis Mamani", "4-4567890", "info@modaimport.com"),
        ("Distribuidora Central", "Patricia López", "2-5678901", "ventas@distcentral.com"),
        ("Confecciones del Sur", "Roberto Flores", "4-6789012", "pedidos@confsur.com"),
    ]
    nuevos = 0
    for nombre, contacto, telefono, email in proveedores:
        _, creado = _get_or_create(
            db,
            Proveedor,
            nombre=nombre,
            defaults={
                "contacto": contacto,
                "telefono": telefono,
                "email": email,
                "activo": True,
            },
        )
        nuevos += int(creado)
    print(f"  Proveedores nuevos: {nuevos}")


def sembrar_temporadas(db):
    temporadas = [
        ("Primavera-Verano 2026", "Ropa ligera para clima cálido"),
        ("Otoño-Invierno 2026", "Ropa de abrigo para clima frío"),
        ("Temporada Escolar", "Uniformes y ropa escolar"),
        ("Promociones Especiales", "Ofertas y liquidaciones"),
    ]
    nuevos = 0
    for nombre, desc in temporadas:
        _, creado = _get_or_create(
            db, Temporada, nombre=nombre, defaults={"descripcion": desc, "activo": True}
        )
        nuevos += int(creado)
    print(f"  Temporadas nuevas: {nuevos}")


def sembrar_colecciones(db):
    colecciones = [
        ("Urbana 2026", "Estilo urbano contemporáneo"),
        ("Clásica Premium", "Prendas formales de alta calidad"),
        ("Sport Active", "Ropa deportiva funcional"),
        ("Casual Weekend", "Estilo relajado de fin de semana"),
    ]
    nuevos = 0
    for nombre, desc in colecciones:
        _, creado = _get_or_create(
            db, Coleccion, nombre=nombre, defaults={"descripcion": desc, "activo": True}
        )
        nuevos += int(creado)
    print(f"  Colecciones nuevas: {nuevos}")


def sembrar_tallas(db):
    tallas = ["XS", "S", "M", "L", "XL", "XXL", "36", "38", "40", "42", "44"]
    nuevos = 0
    for nombre in tallas:
        _, creado = _get_or_create(db, Talla, nombre=nombre, defaults={"activo": True})
        nuevos += int(creado)
    print(f"  Tallas nuevas: {nuevos}")


def sembrar_colores(db):
    colores = [
        ("Negro", "#000000"),
        ("Blanco", "#FFFFFF"),
        ("Azul", "#0000FF"),
        ("Rojo", "#FF0000"),
        ("Verde", "#00FF00"),
        ("Gris", "#808080"),
        ("Beige", "#F5F5DC"),
        ("Marrón", "#8B4513"),
        ("Azul Marino", "#000080"),
        ("Vino", "#722F37"),
    ]
    nuevos = 0
    for nombre, hex_ in colores:
        _, creado = _get_or_create(
            db, Color, nombre=nombre, defaults={"codigo_hex": hex_, "activo": True}
        )
        nuevos += int(creado)
    print(f"  Colores nuevos: {nuevos}")


def sembrar_tipos_prenda(db):
    tipos = [
        ("Camisa Formal", "Camisa de vestir"),
        ("Camisa Casual", "Camisa informal"),
        ("Pantalón de Vestir", "Pantalón formal"),
        ("Jean", "Pantalón de mezclilla"),
        ("Zapato Formal", "Calzado de vestir"),
        ("Zapatilla", "Calzado deportivo"),
        ("Chaqueta", "Prenda de abrigo"),
        ("Polera", "Prenda casual"),
    ]
    nuevos = 0
    for nombre, desc in tipos:
        _, creado = _get_or_create(
            db, TipoPrenda, nombre=nombre, defaults={"descripcion": desc, "activo": True}
        )
        nuevos += int(creado)
    print(f"  Tipos de prenda nuevos: {nuevos}")


def sembrar_productos(db):
    """Crea 15 productos con variantes e inventario."""
    # Cargar catálogos para referencias
    cats = {c.nombre: c for c in db.query(Categoria).all()}
    marcas = {m.nombre: m for m in db.query(Marca).all()}
    provs = {p.nombre: p for p in db.query(Proveedor).all()}
    temps = {t.nombre: t for t in db.query(Temporada).all()}
    cols = {c.nombre: c for c in db.query(Coleccion).all()}
    tipos = {t.nombre: t for t in db.query(TipoPrenda).all()}
    tallas = {t.nombre: t for t in db.query(Talla).all()}
    colores = {c.nombre: c for c in db.query(Color).all()}
    sucursales = db.query(Sucursal).all()

    # (nombre, desc, precio, categoria, marca, proveedor, temporada, coleccion, tipo, imagen_url)
    productos_data = [
        ("Camisa Formal Blanca", "Camisa de vestir manga larga", 180, "Camisas", "Zara", "Textiles Bolivia S.A.", "Primavera-Verano 2026", "Clásica Premium", "Camisa Formal", "/imagenes/camisas/camisa-formal-blanca.jpg"),
        ("Camisa Casual Azul", "Camisa casual de algodón", 150, "Camisas", "H&M", "Importadora Andina", "Primavera-Verano 2026", "Urbana 2026", "Camisa Casual", "/imagenes/camisas/camisa-casual-azul.jpg"),
        ("Pantalón de Vestir Negro", "Pantalón formal de corte recto", 250, "Pantalones", "Zara", "Textiles Bolivia S.A.", "Otoño-Invierno 2026", "Clásica Premium", "Pantalón de Vestir", "/imagenes/pantalones/pantalon-vestir-negro.jpg"),
        ("Jean Clásico Azul", "Jean de mezclilla corte regular", 220, "Pantalones", "Levi's", "Moda Import SRL", "Primavera-Verano 2026", "Casual Weekend", "Jean", "/imagenes/pantalones/jean-clasico-azul.jpg"),
        ("Zapato Formal Negro", "Zapato de cuero para vestir", 380, "Zapatos", "Tommy Hilfiger", "Distribuidora Central", "Otoño-Invierno 2026", "Clásica Premium", "Zapato Formal", "/imagenes/zapatos/zapato-formal-negro.jpg"),
        ("Zapatilla Deportiva Blanca", "Zapatilla para running", 420, "Zapatos", "Nike", "Distribuidora Central", "Primavera-Verano 2026", "Sport Active", "Zapatilla", "/imagenes/zapatos/zapatilla-deportiva-blanca.jpg"),
        ("Zapatilla Urbana Negra", "Zapatilla casual urbana", 350, "Zapatos", "Adidas", "Distribuidora Central", "Primavera-Verano 2026", "Urbana 2026", "Zapatilla", "/imagenes/zapatos/zapatilla-urbana-negra.jpg"),
        ("Chaqueta de Cuero", "Chaqueta de cuero genuino", 650, "Chaquetas", "Zara", "Moda Import SRL", "Otoño-Invierno 2026", "Clásica Premium", "Chaqueta", "/imagenes/chaquetas/chaqueta-cuero.jpg"),
        ("Chaqueta Deportiva", "Chaqueta cortavientos", 300, "Chaquetas", "Nike", "Distribuidora Central", "Otoño-Invierno 2026", "Sport Active", "Chaqueta", "/imagenes/chaquetas/chaqueta-deportiva.jpg"),
        ("Polera Básica Negra", "Polera de algodón cuello redondo", 90, "Poleras", "H&M", "Importadora Andina", "Primavera-Verano 2026", "Casual Weekend", "Polera", "/imagenes/poleras/polera-basica-negra.jpg"),
        ("Polera Estampada", "Polera con diseño gráfico", 110, "Poleras", "H&M", "Importadora Andina", "Primavera-Verano 2026", "Urbana 2026", "Polera", "/imagenes/poleras/polera-estampada.jpg"),
        ("Traje Completo Gris", "Traje de 2 piezas color gris", 1200, "Trajes", "Tommy Hilfiger", "Textiles Bolivia S.A.", "Otoño-Invierno 2026", "Clásica Premium", "Camisa Formal", "/imagenes/trajes/traje-completo-gris.jpg"),
        ("Short Deportivo", "Short para entrenamiento", 130, "Ropa Deportiva", "Adidas", "Distribuidora Central", "Primavera-Verano 2026", "Sport Active", "Jean", "/imagenes/ropa-deportiva/short-deportivo.jpg"),
        ("Cinturón de Cuero", "Cinturón formal de cuero", 120, "Accesorios", "Tommy Hilfiger", "Distribuidora Central", "Otoño-Invierno 2026", "Clásica Premium", "Camisa Formal", "/imagenes/accesorios/cinturon-cuero.jpg"),
        ("Bufanda de Lana", "Bufanda tejida para invierno", 80, "Accesorios", "H&M", "Importadora Andina", "Otoño-Invierno 2026", "Casual Weekend", "Chaqueta", "/imagenes/accesorios/bufanda-lana.jpg"),
    ]

    productos_nuevos = 0
    variantes_nuevas = 0
    inventarios_nuevos = 0

    for (nombre, desc, precio, cat, mar, prov, temp, cole, tipo, imagen) in productos_data:
        prod, creado = _get_or_create(
            db,
            Producto,
            nombre=nombre,
            defaults={
                "descripcion": desc,
                "precio": Decimal(str(precio)),
                "categoria_id": cats[cat].id,
                "marca_id": marcas[mar].id,
                "proveedor_id": provs[prov].id,
                "temporada_id": temps[temp].id,
                "coleccion_id": cols[cole].id,
                "tipo_prenda_id": tipos[tipo].id,
                "imagen_url": imagen,
                "activo": True,
            },
        )
        productos_nuevos += int(creado)

        # Crear 3 variantes por producto (M, L, XL) con 3 colores
        for talla_n, color_n in [("M", "Negro"), ("L", "Azul"), ("XL", "Blanco")]:
            var, creado_var = _get_or_create(
                db,
                ProductoVariante,
                producto_id=prod.id,
                talla_id=tallas[talla_n].id,
                color_id=colores[color_n].id,
                defaults={"activo": True},
            )
            variantes_nuevas += int(creado_var)

            # Inventario en cada sucursal
            for suc in sucursales:
                _, creado_inv = _get_or_create(
                    db,
                    Inventario,
                    variante_id=var.id,
                    sucursal_id=suc.id,
                    defaults={"cantidad": 10, "cantidad_reservada": 0},
                )
                inventarios_nuevos += int(creado_inv)

    print(f"  Productos nuevos: {productos_nuevos}")
    print(f"  Variantes nuevas: {variantes_nuevas}")
    print(f"  Inventarios nuevos: {inventarios_nuevos}")


def main():
    print("=" * 60)
    print("SEED DEMO - MenStyle")
    print("=" * 60)
    db = SessionLocal()
    try:
        print("\n[1/10] Sembrando roles...")
        sembrar_roles(db)
        print("\n[2/10] Sembrando usuarios...")
        sembrar_usuarios(db)
        print("\n[3/10] Sembrando sucursales...")
        sembrar_sucursales(db)
        print("\n[4/10] Sembrando categorías...")
        sembrar_categorias(db)
        print("\n[5/10] Sembrando marcas...")
        sembrar_marcas(db)
        print("\n[6/10] Sembrando proveedores...")
        sembrar_proveedores(db)
        print("\n[7/10] Sembrando temporadas...")
        sembrar_temporadas(db)
        print("\n[8/10] Sembrando colecciones...")
        sembrar_colecciones(db)
        print("\n[9/10] Sembrando tallas, colores, tipos...")
        sembrar_tallas(db)
        sembrar_colores(db)
        sembrar_tipos_prenda(db)
        print("\n[10/10] Sembrando productos + variantes + inventario...")
        sembrar_productos(db)

        db.commit()
        print("\n" + "=" * 60)
        print("✅ SEED COMPLETADO")
        print("=" * 60)
    except Exception as e:
        db.rollback()
        print(f"\n❌ ERROR: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
