"""Agregar campo imagen_url a colores

Revision ID: c3a2b1d0e9f8
Revises: 4735b2eae240
Create Date: 2026-09-23 16:10:00

Caso de uso: CU25 - Consultar Disponibilidad (imagen dinámica por color)
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c3a2b1d0e9f8'
down_revision: Union[str, Sequence[str], None] = '4735b2eae240'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Agrega columna imagen_url a la tabla colores."""
    op.add_column(
        'colores',
        sa.Column('imagen_url', sa.String(length=500), nullable=True)
    )


def downgrade() -> None:
    """Elimina la columna imagen_url de colores."""
    op.drop_column('colores', 'imagen_url')