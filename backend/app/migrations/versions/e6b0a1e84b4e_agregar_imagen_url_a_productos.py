"""Agregar campo imagen_url a productos

Revision ID: e6b0a1e84b4e
Revises: b2c3d4e5f6a7
Create Date: 2026-09-18 13:57:02

Caso de uso: CU13 - Gestionar Imágenes
Requisito funcional: RF04 - Gestionar productos de ropa
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e6b0a1e84b4e'
down_revision: Union[str, Sequence[str], None] = 'b2c3d4e5f6a7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Agrega columna imagen_url a la tabla productos."""
    op.add_column(
        'productos',
        sa.Column('imagen_url', sa.String(length=500), nullable=True)
    )


def downgrade() -> None:
    """Elimina la columna imagen_url."""
    op.drop_column('productos', 'imagen_url')
