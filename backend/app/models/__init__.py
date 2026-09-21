"""
Registro de todos los modelos SQLAlchemy de MenStyle.

Importar este módulo garantiza que todas las clases estén registradas
en el metadata de SQLAlchemy, lo que permite:
- Resolver ForeignKeys correctamente
- Autogenerar migraciones con Alembic
- Ejecutar seeds y scripts sin NoReferencedTableError
"""

from app.models.user import Usuario
from app.models.role import Rol
from app.models.permission import Permiso, RolPermiso

from app.models.category import Categoria
from app.models.brand import Marca
from app.models.size import Talla
from app.models.color import Color
from app.models.garment_type import TipoPrenda
from app.models.season import Temporada
from app.models.collection import Coleccion
from app.models.supplier import Proveedor
from app.models.branch import Sucursal
from app.models.discount import Descuento

from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.inventory import Inventario

from app.models.cart import Carrito
from app.models.cart_detail import DetalleCarrito

from app.models.order import Pedido
from app.models.order_detail import DetallePedido

from app.models.payment import Pago
from app.models.payment_type import TipoPago

from app.models.reservation import Reserva
from app.models.reservation_detail import DetalleReserva

from app.models.return_model import Devolucion
from app.models.notification import Notificacion
from app.models.password_reset_token import PasswordResetToken


__all__ = [
    "Usuario",
    "Rol",
    "Permiso",
    "RolPermiso",
    "Categoria",
    "Marca",
    "Talla",
    "Color",
    "TipoPrenda",
    "Temporada",
    "Coleccion",
    "Proveedor",
    "Sucursal",
    "Descuento",
    "Producto",
    "ProductoVariante",
    "Inventario",
    "Carrito",
    "DetalleCarrito",
    "Pedido",
    "DetallePedido",
    "Pago",
    "TipoPago",
    "Reserva",
    "DetalleReserva",
    "Devolucion",
    "Notificacion",
    "PasswordResetToken",
]
