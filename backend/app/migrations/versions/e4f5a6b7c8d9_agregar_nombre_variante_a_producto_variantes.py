"""Agregar campo nombre_variante a producto_variantes

Revision ID: e4f5a6b7c8d9
Revises: c3a2b1d0e9f8
Create Date: 2026-09-23 18:00:00

Motivo: nombre dinámico según la variante (talla + color) en el detalle de producto.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e4f5a6b7c8d9'
down_revision: Union[str, Sequence[str], None] = 'c3a2b1d0e9f8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Agrega columna nombre_variante a la tabla producto_variantes."""
    op.add_column(
        'producto_variantes',
        sa.Column('nombre_variante', sa.String(length=120), nullable=True)
    )


def downgrade() -> None:
    """Elimina la columna nombre_variante de producto_variantes."""
    op.drop_column('producto_variantes', 'nombre_variante')