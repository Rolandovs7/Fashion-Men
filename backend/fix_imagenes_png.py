"""
Fix: actualizar rutas de imagenes de camisas de JPG a PNG.

Uso:
  cd backend
  source ../.venv/bin/activate
  python fix_imagenes_png.py
"""
from app.core.database import SessionLocal
from app.models.product import Producto
from app.models.product_variant import ProductoVariante

CAMBIOS = {
    '/imagenes/camisas/camisa-formal-blanca.jpg':   '/imagenes/camisas/camisa-formal-blanca-png.png',
    '/imagenes/camisas/camisa-formal-azul.jpg':     '/imagenes/camisas/camisa-formal-azul-png.png',
    '/imagenes/camisas/camisa-formal-celeste.jpg':  '/imagenes/camisas/camisa-formal-celeste-png.png',
    '/imagenes/camisas/camisa-casual-azul.jpg':     '/imagenes/camisas/camisa-casual-azul-png.png',
    '/imagenes/camisas/camisa-casual-blanca.jpg':   '/imagenes/camisas/camisa-casual-blanca-png.png',
    '/imagenes/camisas/camisa-casual-gris.jpg':     '/imagenes/camisas/camisa-casual-gris-png.png',
}

def main():
    db = SessionLocal()
    try:
        actualizadas = 0
        for v in db.query(ProductoVariante).all():
            if v.imagen_url in CAMBIOS:
                v.imagen_url = CAMBIOS[v.imagen_url]
                actualizadas += 1
        for p in db.query(Producto).all():
            if p.imagen_url in CAMBIOS:
                p.imagen_url = CAMBIOS[p.imagen_url]
                actualizadas += 1
        db.commit()
        print(f'OK: {actualizadas} registros actualizados')
    except Exception as e:
        db.rollback()
        print(f'ERROR: {e}')
        raise
    finally:
        db.close()

if __name__ == '__main__':
    main()