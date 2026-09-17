from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes.auth import router as auth_router
from app.api.routes.categories import router as categories_router
from app.api.routes.products import router as products_router
from app.api.routes.product_variants import router as product_variants_router
from app.api.routes.sizes import router as sizes_router
from app.api.routes.colors import router as colors_router
from app.api.routes.branches import router as branches_router
from app.api.routes.roles import router as roles_router
from app.api.routes.payment_types import router as payment_types_router
from app.api.routes.suppliers import router as suppliers_router
from app.api.routes.garment_types import router as garment_types_router
from app.api.routes.brands import router as brands_router
from app.api.routes.discounts import router as discounts_router
from app.api.routes.seasons import router as seasons_router
from app.api.routes.collections import router as collections_router
from app.api.routes.inventory import router as inventory_router
from app.api.routes.cart import router as cart_router
from app.api.routes.reservations import router as reservations_router
from app.api.routes.notifications import router as notifications_router
from app.api.routes.orders import router as orders_router
from app.api.routes.payments import router as payments_router
from app.api.routes.returns import router as returns_router
from app.api.routes.users import router as users_router
from app.api.routes.permissions import router as permissions_router
from app.api.routes.ia import router as ia_router                              # ← NUEVA (CU31, CU32 - RF25)

app = FastAPI(
    title="MenStyle API",
    description="API de comercio electrónico de ropa masculina",
    version="1.0.0"
)

# ============================================
# CONFIGURACIÓN CORS
# ============================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# ROUTERS
# ============================================
app.include_router(auth_router, prefix="/api/auth", tags=["Autenticación"])
app.include_router(categories_router, prefix="/api/categorias", tags=["Categorías"])
app.include_router(products_router, prefix="/api/productos", tags=["Productos"])
app.include_router(product_variants_router, prefix="/api/variantes", tags=["Variantes"])
app.include_router(sizes_router, prefix="/api/tallas", tags=["Tallas"])
app.include_router(colors_router, prefix="/api/colores", tags=["Colores"])
app.include_router(branches_router, prefix="/api/sucursales", tags=["Sucursales"])
app.include_router(roles_router, prefix="/api/roles", tags=["Roles"])
app.include_router(payment_types_router, prefix="/api/tipos-pago", tags=["Tipos de Pago"])
app.include_router(suppliers_router, prefix="/api/proveedores", tags=["Proveedores"])
app.include_router(garment_types_router, prefix="/api/tipos-prenda", tags=["Tipos de Prenda"])
app.include_router(brands_router, prefix="/api/marcas", tags=["Marcas"])
app.include_router(discounts_router, prefix="/api/descuentos", tags=["Descuentos"])
app.include_router(seasons_router, prefix="/api/temporadas", tags=["Temporadas"])
app.include_router(collections_router, prefix="/api/colecciones", tags=["Colecciones"])
app.include_router(inventory_router, prefix="/api/inventario", tags=["Inventario"])
app.include_router(cart_router, prefix="/api/carrito", tags=["Carrito"])
app.include_router(reservations_router, prefix="/api/reservas", tags=["Reservas"])
app.include_router(notifications_router, prefix="/api/notificaciones", tags=["Notificaciones"])
app.include_router(orders_router, prefix="/api/pedidos", tags=["Pedidos"])
app.include_router(payments_router, prefix="/api/pagos", tags=["Pagos"])
app.include_router(returns_router, prefix="/api/devoluciones", tags=["Devoluciones"])
app.include_router(users_router, prefix="/api")
app.include_router(permissions_router, prefix="/api")

# ============================================
# ROUTERS - INTELIGENCIA ARTIFICIAL (RF25)
# ============================================
# CU31 - Recibir Recomendaciones (IA)
# CU32 - Interactuar con Asistente Virtual
app.include_router(ia_router, prefix="/api/ia", tags=["Inteligencia Artificial"])

# ============================================
# ENDPOINTS DE PRUEBA
# ============================================
@app.get("/")
def inicio():
    return {
        "mensaje": "Bienvenido a MenStyle API",
        "estado": "funcionando",
        "documentacion": "/docs"
    }


@app.get("/saludo")
def saludo():
    return {
        "mensaje": "MenStyle está funcionando correctamente"
    }