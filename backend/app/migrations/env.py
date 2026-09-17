from logging.config import fileConfig
import os

from sqlalchemy import engine_from_config
from sqlalchemy import pool

from alembic import context
from dotenv import load_dotenv

from app.core.database import Base

from app.models.user import Usuario
from app.models.category import Categoria
from app.models.size import Talla
from app.models.color import Color
from app.models.product import Producto
from app.models.product_variant import ProductoVariante
from app.models.branch import Sucursal
from app.models.inventory import Inventario
from app.models.season import Temporada
from app.models.collection import Coleccion
from app.models.supplier import Proveedor
from app.models.reservation import Reserva
from app.models.reservation_detail import DetalleReserva
from app.models.cart import Carrito
from app.models.cart_detail import DetalleCarrito
from app.models.order import Pedido
from app.models.order_detail import DetallePedido
from app.models.payment import Pago
from app.models.return_model import Devolucion
from app.models.notification import Notificacion
from app.models.permission import Permiso, RolPermiso

# Cargar variables del archivo .env
load_dotenv()

# Configuración de Alembic
config = context.config

# Configurar logging
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Metadata de SQLAlchemy para detectar modelos
target_metadata = Base.metadata

# Obtener URL de PostgreSQL desde .env
database_url = os.getenv("DATABASE_URL")

if not database_url:
    raise ValueError(
        "DATABASE_URL no está configurada en el archivo .env"
    )

# Reemplazar la URL de alembic.ini
config.set_main_option(
    "sqlalchemy.url",
    database_url
)


def run_migrations_offline() -> None:
    """Ejecutar migraciones en modo offline."""

    url = config.get_main_option("sqlalchemy.url")

    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Ejecutar migraciones en modo online."""

    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:

        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
