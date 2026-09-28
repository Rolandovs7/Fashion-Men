"""Agregar campo imagen_url a producto_variantes

Revision ID: 80ec04e375f9
Revises: e4f5a6b7c8d9
Create Date: 2026-09-23 18:19:06.807543

Motivo: cada variante (talla + color) tendrá su propia imagen local,
independiente del color usado en otros productos.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '80ec04e375f9'
down_revision: Union[str, Sequence[str], None] = 'e4f5a6b7c8d9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Agrega columna imagen_url a la tabla producto_variantes."""
    op.add_column(
        'producto_variantes',
        sa.Column('imagen_url', sa.String(length=500), nullable=True)
    )


def downgrade() -> None:
    """Elimina la columna imagen_url de producto_variantes."""
    op.drop_column('producto_variantes', 'imagen_url')
