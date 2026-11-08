"""
Seed: clona productos (y variantes) de MenStyle (empresa_id=1) hacia Avenor (empresa_id=2)
para categorías relacionadas con ropa deportiva, chaquetas o pantalones, y asigna
inventario inicial (20 unidades por variante) en las sucursales de Avenor.

Idempotente: no duplica productos/variantes/inventarios si se ejecuta varias veces.

Uso (local, usando .env/DATABASE_URL del proyecto):
  cd backend
  ../.venv/bin/python seed_avenor.py

Uso contra Render (reemplaza con tu DATABASE_URL real de Render):
  cd backend
  DATABASE_URL='postgresql://USER:PASSWORD@HOST/DBNAME' ../.venv/bin/python seed_avenor.py
"""

import os
import sys

from sqlalchemy import func

# Permite ejecutar como script desde la carpeta backend
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.models.saas import Empresa
from app.models.branch import Sucursal
from app.models.category import Categoria
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.inventory import Inventario

MENSTYLE_EMPRESA_ID = 1
AVENOR_NOMBRE = "Avenor"
AVENOR_EMPRESA_ID_FALLBACK = 2
CATEGORIA_TERMINOS = ("deport", "chaquet", "pantal")  # match flexible (deportiva, chaqueta, pantalón/pantalones)
STOCK_INICIAL = 20


def _obtener_avenor(db):
    emp = db.query(Empresa).filter(Empresa.nombre == AVENOR_NOMBRE).first()
    if emp:
        return emp
    return db.query(Empresa).filter(Empresa.id == AVENOR_EMPRESA_ID_FALLBACK).first()


def seed_avenor():
    db = SessionLocal()
    try:
        avenor = _obtener_avenor(db)
        if not avenor:
            print(f"ERROR: No se encontró la empresa '{AVENOR_NOMBRE}' (ni id={AVENOR_EMPRESA_ID_FALLBACK}).")
            print("Cree la empresa Avenor primero (empresa_id=2) y vuelva a ejecutar.")
            return 1

        print(f"Empresa destino: {avenor.nombre} (id={avenor.id})")

        # Categorías globales que matchean los términos
        categorias = db.query(Categoria).all()
        categorias_match = []
        for c in categorias:
            nombre = (c.nombre or "").lower()
            if any(t in nombre for t in CATEGORIA_TERMINOS):
                categorias_match.append(c)

        if not categorias_match:
            print("No se encontraron categorías relacionadas con ropa deportiva/chaquetas/pantalones.")
            return 1

        cat_ids = [c.id for c in categorias_match]
        print("Categorías seleccionadas:")
        for c in categorias_match:
            print(f"  - [{c.id}] {c.nombre}")

        # Sucursales de Avenor
        sucursales = (
            db.query(Sucursal)
            .filter(Sucursal.empresa_id == avenor.id)
            .order_by(Sucursal.id.asc())
            .all()
        )
        if not sucursales:
            print(f"ADVERTENCIA: Avenor (id={avenor.id}) no tiene sucursales. Se clonarán productos/variantes pero NO se creará inventario.")
        else:
            print("Sucursales de Avenor:")
            for s in sucursales:
                print(f"  - [{s.id}] {s.nombre} ({s.ciudad})")

        # Productos fuente (MenStyle)
        productos_fuente = (
            db.query(Producto)
            .filter(Producto.empresa_id == MENSTYLE_EMPRESA_ID, Producto.categoria_id.in_(cat_ids))
            .order_by(Producto.id.asc())
            .all()
        )
        if not productos_fuente:
            print("No se encontraron productos de MenStyle (empresa_id=1) en las categorías seleccionadas.")
            return 1

        print(f"Productos fuente encontrados: {len(productos_fuente)}")

        productos_creados = 0
        productos_existentes = 0
        variantes_creadas = 0
        variantes_existentes = 0
        inventarios_creados = 0
        inventarios_existentes = 0

        for src in productos_fuente:
            # Idempotencia producto: mismo nombre dentro de Avenor
            dst = (
                db.query(Producto)
                .filter(
                    Producto.empresa_id == avenor.id,
                    func.lower(Producto.nombre) == func.lower(src.nombre),
                )
                .first()
            )
            if not dst:
                dst = Producto(
                    nombre=src.nombre,
                    descripcion=src.descripcion,
                    imagen_url=src.imagen_url,
                    modelo_ar_url=src.modelo_ar_url,
                    precio=src.precio,
                    precio_mayorista=getattr(src, "precio_mayorista", None),
                    cantidad_mayorista=getattr(src, "cantidad_mayorista", None),
                    categoria_id=src.categoria_id,
                    proveedor_id=getattr(src, "proveedor_id", None),
                    temporada_id=getattr(src, "temporada_id", None),
                    coleccion_id=getattr(src, "coleccion_id", None),
                    tipo_prenda_id=getattr(src, "tipo_prenda_id", None),
                    marca_id=getattr(src, "marca_id", None),
                    descuento_id=getattr(src, "descuento_id", None),
                    empresa_id=avenor.id,
                    activo=bool(getattr(src, "activo", True)),
                )
                db.add(dst)
                db.flush()
                productos_creados += 1
                print(f"  + Producto clonado: [{src.id}] {src.nombre} -> [{dst.id}] (Avenor)")
            else:
                productos_existentes += 1
                print(f"  = Producto ya existe: {src.nombre} (Avenor id={dst.id}), se verifica variantes/inventario")

            # Variantes fuente
            variantes_src = (
                db.query(ProductoVariante)
                .filter(ProductoVariante.producto_id == src.id)
                .order_by(ProductoVariante.id.asc())
                .all()
            )
            for vsrc in variantes_src:
                vdst = (
                    db.query(ProductoVariante)
                    .filter(
                        ProductoVariante.producto_id == dst.id,
                        ProductoVariante.talla_id == vsrc.talla_id,
                        ProductoVariante.color_id == vsrc.color_id,
                    )
                    .first()
                )
                if not vdst:
                    vdst = ProductoVariante(
                        producto_id=dst.id,
                        talla_id=vsrc.talla_id,
                        color_id=vsrc.color_id,
                        nombre_variante=getattr(vsrc, "nombre_variante", None),
                        imagen_url=getattr(vsrc, "imagen_url", None),
                        activo=bool(getattr(vsrc, "activo", True)),
                    )
                    db.add(vdst)
                    db.flush()
                    variantes_creadas += 1
                else:
                    variantes_existentes += 1

                # Inventario inicial en cada sucursal de Avenor (no destructivo)
                for suc in sucursales:
                    inv = (
                        db.query(Inventario)
                        .filter(Inventario.variante_id == vdst.id, Inventario.sucursal_id == suc.id)
                        .first()
                    )
                    if not inv:
                        inv = Inventario(
                            variante_id=vdst.id,
                            sucursal_id=suc.id,
                            cantidad=STOCK_INICIAL,
                            cantidad_reservada=0,
                        )
                        db.add(inv)
                        db.flush()
                        inventarios_creados += 1
                    else:
                        inventarios_existentes += 1

        db.commit()
        print("\nResumen seed_avenor:")
        print(f"  Productos creados: {productos_creados} | ya existentes: {productos_existentes}")
        print(f"  Variantes creadas: {variantes_creadas} | ya existentes: {variantes_existentes}")
        print(f"  Inventarios creados: {inventarios_creados} | ya existentes: {inventarios_existentes}")
        print("Listo.")
        return 0
    except Exception as e:
        db.rollback()
        print(f"ERROR: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(seed_avenor())
