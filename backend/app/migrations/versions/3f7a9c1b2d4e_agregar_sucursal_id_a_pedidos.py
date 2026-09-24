"""Agregar sucursal_id a pedidos para reposicion de stock al cancelar

Revision ID: 3f7a9c1b2d4e
Revises: 80ec04e375f9
Create Date: 2026-09-24 16:20:00.000000

Motivo: al cancelar un pedido el backend repone el stock, pero ahora que
existen varias sucursales activas no sabe a cuál reponer. Guardar la
sucursal de origen en el pedido permite reponer el stock SOLO en esa
sucursal (con fallback a la lógica anterior para pedidos viejos sin el dato).
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3f7a9c1b2d4e'
down_revision: Union[str, Sequence[str], None] = '80ec04e375f9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Agrega la columna sucursal_id (FK a sucursales) a la tabla pedidos."""
    op.add_column(
        'pedidos',
        sa.Column('sucursal_id', sa.Integer(), nullable=True)
    )
    op.create_foreign_key(
        'fk_pedidos_sucursal',
        'pedidos', 'sucursales',
        ['sucursal_id'], ['id']
    )
    op.create_index(
        'ix_pedidos_sucursal_id',
        'pedidos', ['sucursal_id']
    )


def downgrade() -> None:
    """Elimina la columna sucursal_id de la tabla pedidos."""
    op.drop_index('ix_pedidos_sucursal_id', table_name='pedidos')
    op.drop_constraint('fk_pedidos_sucursal', 'pedidos', type_='foreignkey')
    op.drop_column('pedidos', 'sucursal_id')