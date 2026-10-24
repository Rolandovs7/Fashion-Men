#!/usr/bin/env python3
"""
Actualiza imagen_url de la tabla productos (y opcionalmente producto_variantes)
para que coincida con los archivos reales de frontend/public/imagenes/.

Uso local:
    export DATABASE_URL='postgresql://usuario:password@host:5432/db?sslmode=require'
    python actualizar_imagenes_render.py --variantes

Uso dentro de Render (Shell o Job, desde /app):
    python actualizar_imagenes_render.py --variantes

Opciones:
    --variantes   También actualiza producto_variantes (recomendado).
    --dry-run     Muestra qué cambiaría, sin escribir en la DB.

El script no importa la app ni carga .env: usa exclusivamente DATABASE_URL
para evitar conectarse por accidente a una base local.
"""

from __future__ import annotations

import argparse
import os
import sys
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError


# ------------------------------------------------------------
# Imagen principal de cada producto (21 productos de la DB).
# Todas las rutas apuntan a archivos que existen en
# frontend/public/imagenes/.
# ------------------------------------------------------------
IMAGENES_PRODUCTOS = {
    # Productos 1-15 (seed_demo.py)
    "Camisa Formal Blanca":       "/imagenes/camisas/camisa-formal-blanca-png.png",
    "Camisa Casual Azul":         "/imagenes/camisas/camisa-casual-azul-png.png",
    "Pantalón de Vestir Negro":   "/imagenes/pantalones/pantalon-vestir-negro.jpg",
    "Jean Clásico Azul":          "/imagenes/pantalones/jean-clasico-azul.jpg",
    "Zapato Formal Negro":        "/imagenes/zapatos/zapato-formal-negro.jpg",
    "Zapatilla Deportiva Blanca": "/imagenes/zapatos/zapatilla-deportiva-blanca.jpg",
    "Zapatilla Urbana Negra":     "/imagenes/zapatos/zapatilla-urbana-negra.jpg",
    "Chaqueta de Cuero":          "/imagenes/chaquetas/chaqueta-cuero-negro-png.png",
    "Chaqueta Deportiva":         "/imagenes/chaquetas/chaqueta-deportiva-negro-png.png",
    "Polera Básica Negra":        "/imagenes/poleras/polera-basica-negro-png.png",
    "Polera Estampada":           "/imagenes/poleras/polera-estampada-negro-png.png",
    "Traje Completo Gris":        "/imagenes/trajes/traje-completo-gris.jpg",
    "Short Deportivo":            "/imagenes/ropa-deportiva/short-negro.jpg",
    "Cinturón de Cuero":          "/imagenes/accesorios/cinturon-cuero-marron.jpg",
    "Bufanda de Lana":            "/imagenes/accesorios/bufanda-gris.jpg",

    # Productos 16-21 (seed_imagenes_variantes.py)
    "Camiseta Básica":            "/imagenes/camisetas/camiseta-basica-negra-png.png",
    "Camisa de Lino":             "/imagenes/camisas/camisa-lino-beige-png.png",
    "Camisa Oxford":              "/imagenes/camisas/camisa-oxford-negro-png.png",
    "Jogger Deportivo":           "/imagenes/pantalones/jogger-negro.jpg",
    "Pantalón Chino":             "/imagenes/pantalones/pantalon-chino-beige.jpg",
    "Mocasín de Cuero":           "/imagenes/zapatos/mocasin-negro.jpg",
}

# ------------------------------------------------------------
# Reemplazos para producto_variantes (--variantes).
# Solo convierte rutas viejas/JPG rotas a archivos existentes.
# ------------------------------------------------------------
CAMBIOS_VARIANTES = {
    # Camisas JPG -> PNG
    "/imagenes/camisas/camisa-formal-blanca.jpg":  "/imagenes/camisas/camisa-formal-blanca-png.png",
    "/imagenes/camisas/camisa-formal-azul.jpg":    "/imagenes/camisas/camisa-formal-azul-png.png",
    "/imagenes/camisas/camisa-formal-celeste.jpg": "/imagenes/camisas/camisa-formal-celeste-png.png",
    "/imagenes/camisas/camisa-casual-blanca.jpg":  "/imagenes/camisas/camisa-casual-blanca-png.png",
    "/imagenes/camisas/camisa-casual-azul.jpg":    "/imagenes/camisas/camisa-casual-azul-png.png",
    "/imagenes/camisas/camisa-casual-gris.jpg":    "/imagenes/camisas/camisa-casual-gris-png.png",
    "/imagenes/camisas/camisa-lino-beige.jpg":     "/imagenes/camisas/camisa-lino-beige-png.png",
    "/imagenes/camisas/camisa-lino-verde.jpg":     "/imagenes/camisas/camisa-lino-verde-png.png",
    "/imagenes/camisas/camisa-oxford-negro.jpg":   "/imagenes/camisas/camisa-oxford-negro-png.png",
    "/imagenes/camisas/camisa-oxford-rojo-vino.jpg": "/imagenes/camisas/camisa-oxford-rojo-vino-png.png",

    # Poleras
    "/imagenes/poleras/polera-basica-negra.jpg":   "/imagenes/poleras/polera-basica-negro-png.png",
    "/imagenes/poleras/polera-basica-blanca.jpg":  "/imagenes/poleras/polera-basica-blanca-png.png",
    "/imagenes/poleras/polera-basica-gris.jpg":    "/imagenes/poleras/polera-basica-gris-png.png",
    "/imagenes/poleras/polera-estampada.jpg":      "/imagenes/poleras/polera-estampada-negro-png.png",
    "/imagenes/poleras/polera-estampada-negro.jpg": "/imagenes/poleras/polera-estampada-negro-png.png",
    "/imagenes/poleras/polera-estampada-azul.jpg": "/imagenes/poleras/polera-estampada-azul-png.png",

    # Chaquetas
    "/imagenes/chaquetas/chaqueta-cuero.jpg":          "/imagenes/chaquetas/chaqueta-cuero-negro-png.png",
    "/imagenes/chaquetas/chaqueta-cuero-negro.jpg":    "/imagenes/chaquetas/chaqueta-cuero-negro-png.png",
    "/imagenes/chaquetas/chaqueta-cuero-marron.jpg":   "/imagenes/chaquetas/chaqueta-cuero-marron-png.png",
    "/imagenes/chaquetas/chaqueta-deportiva.jpg":      "/imagenes/chaquetas/chaqueta-deportiva-negro-png.png",
    "/imagenes/chaquetas/chaqueta-deportiva-azul.jpg": "/imagenes/chaquetas/chaqueta-deportiva-azul-png.png",
    "/imagenes/chaquetas/chaqueta-deportiva-negro.jpg": "/imagenes/chaquetas/chaqueta-deportiva-negro-png.png",

    # Camisetas
    "/imagenes/camisetas/camiseta-basica-negra.jpg":  "/imagenes/camisetas/camiseta-basica-negra-png.png",
    "/imagenes/camisetas/camiseta-basica-blanca.jpg": "/imagenes/camisetas/camiseta-basica-blanca-png.png",

    # Archivos que no existen: se reemplazan por una variante válida
    "/imagenes/ropa-deportiva/short-deportivo.jpg": "/imagenes/ropa-deportiva/short-negro.jpg",
    "/imagenes/accesorios/cinturon-cuero.jpg":      "/imagenes/accesorios/cinturon-cuero-marron.jpg",
    "/imagenes/accesorios/bufanda-lana.jpg":        "/imagenes/accesorios/bufanda-gris.jpg",
}


def normalizar_url(url: str) -> str:
    """Normaliza el scheme y agrega sslmode=require para hosts externos de Render."""
    if url.startswith("postgres://"):
        url = "postgresql://" + url[len("postgres://"):]

    partes = urlsplit(url)
    query = dict(parse_qsl(partes.query, keep_blank_values=True))

    sslmode_env = os.getenv("DB_SSLMODE")
    if sslmode_env:
        query["sslmode"] = sslmode_env
    elif (partes.hostname or "").lower().endswith(".render.com"):
        query.setdefault("sslmode", "require")

    return urlunsplit((partes.scheme, partes.netloc, partes.path, urlencode(query), partes.fragment))


def url_sin_password(url: str) -> str:
    """Devuelve la URL sin la contraseña, para logs seguros."""
    partes = urlsplit(url)
    netloc = partes.netloc
    if "@" in netloc:
        credenciales, host = netloc.rsplit("@", 1)
        if ":" in credenciales:
            usuario, _ = credenciales.split(":", 1)
            credenciales = f"{usuario}:***"
        netloc = f"{credenciales}@{host}"
    return urlunsplit((partes.scheme, netloc, partes.path, partes.query, partes.fragment))


def main() -> int:
    parser = argparse.ArgumentParser(description="Actualiza imagen_url en la DB de Render.")
    parser.add_argument(
        "--variantes",
        action="store_true",
        help="También actualiza producto_variantes (recomendado).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Muestra los cambios sin escribir en la base de datos.",
    )
    args = parser.parse_args()

    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        print("ERROR: falta la variable de entorno DATABASE_URL.", file=sys.stderr)
        print("  Local:  export DATABASE_URL='postgresql://...'", file=sys.stderr)
        print("  Render: la variable ya existe en el servicio.", file=sys.stderr)
        return 1

    url = normalizar_url(database_url)
    print(f"Conectando a: {url_sin_password(url)}")
    print(f"Modo: {'DRY RUN (sin escribir)' if args.dry_run else 'ESCRITURA'}")

    try:
        engine = create_engine(url, pool_pre_ping=True)

        with engine.begin() as conn:
            nombres_db = set(conn.execute(text("SELECT DISTINCT nombre FROM productos")).scalars())
            no_encontrados = sorted(set(IMAGENES_PRODUCTOS) - nombres_db)

            productos_actualizados = 0
            print("\n== Productos ==")
            for nombre, imagen in IMAGENES_PRODUCTOS.items():
                if nombre not in nombres_db:
                    continue

                where = (
                    "nombre = :nombre AND "
                    "(imagen_url IS NULL OR imagen_url <> :imagen)"
                )
                parametros = {"nombre": nombre, "imagen": imagen}

                if args.dry_run:
                    cantidad = conn.execute(
                        text(f"SELECT count(*) FROM productos WHERE {where}"),
                        parametros,
                    ).scalar_one()
                else:
                    resultado = conn.execute(
                        text(f"UPDATE productos SET imagen_url = :imagen WHERE {where}"),
                        parametros,
                    )
                    cantidad = resultado.rowcount

                if cantidad:
                    print(f"  {nombre} -> {imagen}")
                    productos_actualizados += cantidad

            variantes_actualizadas = 0
            if args.variantes:
                print("\n== Variantes ==")
                for vieja, nueva in CAMBIOS_VARIANTES.items():
                    if args.dry_run:
                        cantidad = conn.execute(
                            text("SELECT count(*) FROM producto_variantes WHERE imagen_url = :vieja"),
                            {"vieja": vieja},
                        ).scalar_one()
                    else:
                        resultado = conn.execute(
                            text("UPDATE producto_variantes SET imagen_url = :nueva WHERE imagen_url = :vieja"),
                            {"vieja": vieja, "nueva": nueva},
                        )
                        cantidad = resultado.rowcount

                    if cantidad:
                        print(f"  {vieja} -> {nueva} ({cantidad} variantes)")
                        variantes_actualizadas += cantidad

        print("\n== Resumen ==")
        print(f"  Productos actualizados: {productos_actualizados}")
        if args.variantes:
            print(f"  Variantes actualizadas: {variantes_actualizadas}")
        if no_encontrados:
            print(f"  ⚠ Productos no encontrados en la DB: {no_encontrados}")
        if args.dry_run:
            print("  DRY RUN: no se escribió nada. Quitá --dry-run para aplicar.")
        else:
            print("  ✅ Cambios confirmados (commit OK).")

        return 0

    except SQLAlchemyError as e:
        print(f"\n❌ ERROR de base de datos: {e}", file=sys.stderr)
        print("\nRevisá:", file=sys.stderr)
        print("  - Usar la 'External Database URL' si ejecutás desde tu PC.", file=sys.stderr)
        print("  - Que la URL incluya ?sslmode=require (el script lo agrega solo).", file=sys.stderr)
        print("  - Si el SSL local sigue fallando, ejecutá el script desde Render Shell/Job.", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
