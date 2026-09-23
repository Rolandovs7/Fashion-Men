# ============================================================
# TRAZABILIDAD MENSTYLE
# FEATURE: Imagen por variante (talla + color) + 5 productos nuevos
# RF04 - Gestionar productos de ropa
# RF05 - Gestionar tallas, colores, categorías
# RF07 - Consultar catálogo
# CAPA: Backend FastAPI (Script de fix de datos demo)
# IDEMPOTENTE: sí (se puede ejecutar múltiples veces sin duplicar)
#
# Hace dos cosas:
#   1. Carga imagen_url en cada variante EXISTENTE (productos 1-16)
#      según el color, usando las imágenes locales del frontend.
#   2. Crea 5 productos NUEVOS (Camisa de Lino, Camisa Oxford,
#      Jogger Deportivo, Pantalón Chino, Mocasín) con sus variantes
#      e inventario de stock 10 en la sucursal "MenStyle La Paz Centro".
# ============================================================
from decimal import Decimal

from app.core.database import SessionLocal

from app.models.category import Categoria
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.size import Talla
from app.models.color import Color
from app.models.inventory import Inventario
from app.models.branch import Sucursal


# ------------------------------------------------------------
# 1) IMÁGENES POR COLOR EN VARIANTES EXISTENTES (productos 1-16)
# Formato: { nombre_producto: { nombre_color: url_imagen } }
# ------------------------------------------------------------
IMAGENES_VARIANTES_EXISTENTES = {
    "Camiseta Básica": {
        "Negro": "/imagenes/camisetas/camiseta-basica-negra.jpg",
        "Blanco": "/imagenes/camisetas/camiseta-basica-blanca.jpg",
    },
    "Camisa Formal": {
        "Blanco": "/imagenes/camisas/camisa-formal-blanca.jpg",
        "Azul": "/imagenes/camisas/camisa-formal-azul.jpg",
    },
    "Camisa Casual": {
        "Azul": "/imagenes/camisas/camisa-casual-azul.jpg",
        "Blanco": "/imagenes/camisas/camisa-casual-blanca.jpg",
        "Gris": "/imagenes/camisas/camisa-casual-gris.jpg",
    },
    "Pantalón de Vestir": {
        "Negro": "/imagenes/pantalones/pantalon-vestir-negro.jpg",
        "Azul Marino": "/imagenes/pantalones/pantalon-vestir-azul-marino.jpg",
        "Gris": "/imagenes/pantalones/pantalon-vestir-gris.jpg",
    },
    "Jean Clásico": {
        "Azul": "/imagenes/pantalones/jean-clasico-azul.jpg",
        "Negro": "/imagenes/pantalones/jean-clasico-negro.jpg",
        "Gris": "/imagenes/pantalones/jean-clasico-gris.jpg",
    },
    "Zapato Formal": {
        "Negro": "/imagenes/zapatos/zapato-formal-negro.jpg",
        "Marrón": "/imagenes/zapatos/zapato-formal-marron.jpg",
    },
    "Zapatilla Deportiva": {
        "Blanco": "/imagenes/zapatos/zapatilla-deportiva-blanca.jpg",
        "Negro": "/imagenes/zapatos/zapatilla-deportiva-negro.jpg",
    },
    "Zapatilla Urbana": {
        "Blanco": "/imagenes/zapatos/zapatilla-urbana-blanca.jpg",
        "Negro": "/imagenes/zapatos/zapatilla-urbana-negra.jpg",
    },
    "Chaqueta de Cuero": {
        "Negro": "/imagenes/chaquetas/chaqueta-cuero-negro.jpg",
        "Marrón": "/imagenes/chaquetas/chaqueta-cuero-marron.jpg",
    },
    "Chaqueta Deportiva": {
        "Azul": "/imagenes/chaquetas/chaqueta-deportiva-azul.jpg",
        "Negro": "/imagenes/chaquetas/chaqueta-deportiva-negro.jpg",
    },
    "Polera Básica": {
        "Negro": "/imagenes/camisetas/camiseta-basica-negra.jpg",
        "Blanco": "/imagenes/camisetas/camiseta-basica-blanca.jpg",
        "Gris": "/imagenes/poleras/polera-basica-gris.jpg",
    },
    "Polera Estampada": {
        "Negro": "/imagenes/poleras/polera-estampada-negro.jpg",
        "Azul": "/imagenes/poleras/polera-estampada-azul.jpg",
    },
    "Traje Completo": {
        "Gris": "/imagenes/trajes/traje-completo-gris.jpg",
        "Negro": "/imagenes/trajes/traje-completo-negro.jpg",
        "Azul Marino": "/imagenes/trajes/traje-completo-azul-marino.jpg",
    },
    "Short Deportivo": {
        "Negro": "/imagenes/ropa-deportiva/short-negro.jpg",
        "Azul": "/imagenes/ropa-deportiva/short-azul.jpg",
    },
    "Cinturón de Cuero": {
        "Marrón": "/imagenes/accesorios/cinturon-cuero-marron.jpg",
        "Negro": "/imagenes/accesorios/cinturon-negro.jpg",
    },
    "Bufanda de Lana": {
        "Beige": "/imagenes/accesorios/bufanda-beige.jpg",
        "Gris": "/imagenes/accesorios/bufanda-gris.jpg",
        "Negro": "/imagenes/accesorios/bufanda-negro.jpg",
    },
}

# ------------------------------------------------------------
# 2) PRODUCTOS NUEVOS (17-21)
# Cada variante: tallas x color -> imagen_url
# Inventario: stock 10 en sucursal_id=4
# ------------------------------------------------------------
PRODUCTOS_NUEVOS = [
    {
        "nombre": "Camisa de Lino",
        "descripcion": "Camisa de lino ligera y transpirable, ideal para climas cálidos. Corte relajado con cuello clásico.",
        "precio": 220.00,
        "categoria": "Camisas",
        "imagen_url": "/imagenes/camisas/camisa-lino-beige.jpg",
        "tallas": ["S", "M", "L", "XL"],
        "variantes": [
            ("Beige", "/imagenes/camisas/camisa-lino-beige.jpg"),
            ("Verde", "/imagenes/camisas/camisa-lino-verde.jpg"),
        ],
    },
    {
        "nombre": "Camisa Oxford",
        "descripcion": "Camisa Oxford de algodón con botonadura completa. Un clásico versátil para la oficina y ocasiones formales.",
        "precio": 190.00,
        "categoria": "Camisas",
        "imagen_url": "/imagenes/camisas/camisa-oxford-negro.jpg",
        "tallas": ["S", "M", "L", "XL"],
        "variantes": [
            ("Negro", "/imagenes/camisas/camisa-oxford-negro.jpg"),
            ("Vino", "/imagenes/camisas/camisa-oxford-rojo-vino.jpg"),
        ],
    },
    {
        "nombre": "Jogger Deportivo",
        "descripcion": "Pantalón jogger de tejido técnico con puños elásticos y cintura ajustable. Perfecto para entrenar y el día a día.",
        "precio": 180.00,
        "categoria": "Pantalones",
        "imagen_url": "/imagenes/pantalones/jogger-negro.jpg",
        "tallas": ["S", "M", "L", "XL"],
        "variantes": [
            ("Gris", "/imagenes/pantalones/jogger-gris.jpg"),
            ("Negro", "/imagenes/pantalones/jogger-negro.jpg"),
        ],
    },
    {
        "nombre": "Pantalón Chino",
        "descripcion": "Pantalón chino de corte slim con ajuste cómodo. Algodón de alta calidad, para lo casual y lo formal.",
        "precio": 200.00,
        "categoria": "Pantalones",
        "imagen_url": "/imagenes/pantalones/pantalon-chino-beige.jpg",
        "tallas": ["38", "40", "42", "44"],
        "variantes": [
            ("Azul Marino", "/imagenes/pantalones/pantalon-chino-azul-marino.jpg"),
            ("Beige", "/imagenes/pantalones/pantalon-chino-beige.jpg"),
            ("Negro", "/imagenes/pantalones/pantalon-chino-negro.jpg"),
        ],
    },
    {
        "nombre": "Mocasín de Cuero",
        "descripcion": "Mocasín de cuero genuino con suela de goma. Comodidad y estilo clásico para lucir cualquier día.",
        "precio": 420.00,
        "categoria": "Zapatos",
        "imagen_url": "/imagenes/zapatos/mocasin-negro.jpg",
        "tallas": ["38", "40", "42", "44"],
        "variantes": [
            ("Marrón", "/imagenes/zapatos/mocasin-marron.jpg"),
            ("Negro", "/imagenes/zapatos/mocasin-negro.jpg"),
        ],
    },
]


def cargar_imagenes_variantes_existentes(db):
    """Actualiza imagen_url en las variantes actuales según producto + color."""
    colores = {c.nombre: c for c in db.query(Color).all()}
    actualizadas = 0
    sin_color = []
    sin_producto = []

    for nombre_producto, colores_por_producto in IMAGENES_VARIANTES_EXISTENTES.items():
        producto = db.query(Producto).filter(Producto.nombre == nombre_producto).first()
        if not producto:
            sin_producto.append(nombre_producto)
            continue

        for nombre_color, url in colores_por_producto.items():
            color = colores.get(nombre_color)
            if not color:
                sin_color.append(f"{nombre_producto} / {nombre_color}")
                continue

            variantes = db.query(ProductoVariante).filter(
                ProductoVariante.producto_id == producto.id,
                ProductoVariante.color_id == color.id,
            ).all()

            for variante in variantes:
                if variante.imagen_url != url:
                    variante.imagen_url = url
                    actualizadas += 1

    db.commit()
    print(f"  Variantes con imagen actualizada: {actualizadas}")
    if sin_color:
        print(f"  ⚠ Colores no encontrados: {sin_color}")
    if sin_producto:
        print(f"  ⚠ Productos no encontrados: {sin_producto}")


def crear_productos_nuevos(db):
    """Crea los 5 productos nuevos con variantes e inventario en sucursal 4."""
    sucursal = db.query(Sucursal).filter(Sucursal.id == 4).first()
    if not sucursal:
        raise RuntimeError(
            "No existe la sucursal id=4 (MenStyle La Paz Centro). "
            f"Sucursales disponibles: {[(s.id, s.nombre) for s in db.query(Sucursal).all()]}"
        )

    cats = {c.nombre: c for c in db.query(Categoria).all()}
    tallas = {t.nombre: t for t in db.query(Talla).all()}
    colores = {c.nombre: c for c in db.query(Color).all()}

    productos_nuevos = 0
    variantes_nuevas = 0
    inventarios_nuevos = 0

    for datos in PRODUCTOS_NUEVOS:
        categoria = cats.get(datos["categoria"])
        if not categoria:
            print(f"  ⚠ Categoría '{datos['categoria']}' no encontrada, se omite {datos['nombre']}")
            continue

        producto = db.query(Producto).filter(Producto.nombre == datos["nombre"]).first()
        if not producto:
            producto = Producto(
                nombre=datos["nombre"],
                descripcion=datos["descripcion"],
                precio=Decimal(str(datos["precio"])),
                categoria_id=categoria.id,
                imagen_url=datos["imagen_url"],
                activo=True,
            )
            db.add(producto)
            db.flush()
            productos_nuevos += 1

        for talla_n in datos["tallas"]:
            talla = tallas.get(talla_n)
            if not talla:
                print(f"  ⚠ Talla '{talla_n}' no encontrada, se omite en {datos['nombre']}")
                continue

            for nombre_color, url in datos["variantes"]:
                color = colores.get(nombre_color)
                if not color:
                    print(f"  ⚠ Color '{nombre_color}' no encontrado, se omite en {datos['nombre']}")
                    continue

                variante = db.query(ProductoVariante).filter(
                    ProductoVariante.producto_id == producto.id,
                    ProductoVariante.talla_id == talla.id,
                    ProductoVariante.color_id == color.id,
                ).first()

                if not variante:
                    variante = ProductoVariante(
                        producto_id=producto.id,
                        talla_id=talla.id,
                        color_id=color.id,
                        imagen_url=url,
                        activo=True,
                    )
                    db.add(variante)
                    db.flush()
                    variantes_nuevas += 1
                else:
                    if variante.imagen_url != url or not variante.activo:
                        variante.imagen_url = url
                        variante.activo = True

                inventario = db.query(Inventario).filter(
                    Inventario.variante_id == variante.id,
                    Inventario.sucursal_id == sucursal.id,
                ).first()

                if not inventario:
                    db.add(Inventario(
                        variante_id=variante.id,
                        sucursal_id=sucursal.id,
                        cantidad=10,
                        cantidad_reservada=0,
                    ))
                    inventarios_nuevos += 1

    db.commit()
    print(f"  Productos nuevos: {productos_nuevos}")
    print(f"  Variantes nuevas: {variantes_nuevas}")
    print(f"  Inventarios nuevos (sucursal {sucursal.id}): {inventarios_nuevos}")


def main():
    print("=" * 60)
    print("FIX: Imagen por variante + 5 productos nuevos")
    print("=" * 60)
    db = SessionLocal()
    try:
        print("\n[1/2] Cargando imagen_url en variantes existentes...")
        cargar_imagenes_variantes_existentes(db)
        print("\n[2/2] Creando productos nuevos (17-21)...")
        crear_productos_nuevos(db)
        print("\n" + "=" * 60)
        print("✅ FIX COMPLETADO")
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