"""
Fix: actualizar rutas de imagenes (poleras, chaquetas, camisetas) de JPG a PNG.
"""
from app.core.database import SessionLocal
from app.models.product import Producto
from app.models.product_variant import ProductoVariante

CAMBIOS = {
    # Poleras
    '/imagenes/poleras/polera-basica-negra.jpg':     '/imagenes/poleras/polera-basica-negro-png.png',
    '/imagenes/poleras/polera-basica-blanca.jpg':    '/imagenes/poleras/polera-basica-blanca-png.png',
    '/imagenes/poleras/polera-basica-gris.jpg':      '/imagenes/poleras/polera-basica-gris-png.png',
    '/imagenes/poleras/polera-estampada.jpg':        '/imagenes/poleras/polera-estampada-negro-png.png',
    '/imagenes/poleras/polera-estampada-azul.jpg':   '/imagenes/poleras/polera-estampada-azul-png.png',
    # Chaquetas
    '/imagenes/chaquetas/chaqueta-cuero-negro.jpg':     '/imagenes/chaquetas/chaqueta-cuero-negro-png.png',
    '/imagenes/chaquetas/chaqueta-cuero-marron.jpg':    '/imagenes/chaquetas/chaqueta-cuero-marron-png.png',
    '/imagenes/chaquetas/chaqueta-deportiva-azul.jpg':  '/imagenes/chaquetas/chaqueta-deportiva-azul-png.png',
    '/imagenes/chaquetas/chaqueta-deportiva-negro.jpg': '/imagenes/chaquetas/chaqueta-deportiva-negro-png.png',
    # Camisetas
    '/imagenes/camisetas/camiseta-basica-negra.jpg':  '/imagenes/camisetas/camiseta-basica-negra-png.png',
    '/imagenes/camisetas/camiseta-basica-blanca.jpg': '/imagenes/camisetas/camiseta-basica-blanca-png.png',
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
