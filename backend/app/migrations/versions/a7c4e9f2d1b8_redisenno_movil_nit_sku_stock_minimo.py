"""Rediseño móvil: NIT de empresa, SKU de variante y stock mínimo de producto

Soporte de datos para el rediseño de la app móvil:
- empresas.nit: identificación tributaria del tenant (nullable).
- producto_variantes.sku: código SKU de la variante (nullable, autogenerado en creación).
- productos.stock_minimo: umbral de alerta de reposición (default 5).

Revision ID: a7c4e9f2d1b8
Revises: f9e8d7c6b5a4
Create Date: 2026-11-11
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'a7c4e9f2d1b8'
down_revision: Union[str, Sequence[str], None] = 'f9e8d7c6b5a4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # [SaaS] NIT del tenant (superadmin: registro/listado de empresas)
    with op.batch_alter_table('empresas') as batch_op:
        batch_op.add_column(sa.Column('nit', sa.String(length=50), nullable=True))

    # CU15 / RF21 - SKU por variante
    with op.batch_alter_table('producto_variantes') as batch_op:
        batch_op.add_column(sa.Column('sku', sa.String(length=60), nullable=True))

    # Backfill: SKU determinista para variantes existentes
    op.execute(
        "UPDATE producto_variantes "
        "SET sku = 'MS-P' || producto_id || '-T' || talla_id || '-C' || color_id "
        "WHERE sku IS NULL"
    )

    # CU15 / RF21 - Umbral de stock mínimo por producto
    with op.batch_alter_table('productos') as batch_op:
        batch_op.add_column(
            sa.Column('stock_minimo', sa.Integer(), nullable=False, server_default='5')
        )


def downgrade() -> None:
    with op.batch_alter_table('productos') as batch_op:
        batch_op.drop_column('stock_minimo')

    with op.batch_alter_table('producto_variantes') as batch_op:
        batch_op.drop_column('sku')

    with op.batch_alter_table('empresas') as batch_op:
        batch_op.drop_column('nit')
