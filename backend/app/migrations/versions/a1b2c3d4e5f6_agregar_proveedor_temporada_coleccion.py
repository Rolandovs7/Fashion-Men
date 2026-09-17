"""Agregar proveedor temporada coleccion a productos

Revision ID: a1b2c3d4e5f6
Revises: c29895b2adbc
Create Date: 2026-09-09 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = 'c29895b2adbc'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('productos', sa.Column('proveedor_id', sa.Integer(), nullable=True))
    op.add_column('productos', sa.Column('temporada_id', sa.Integer(), nullable=True))
    op.add_column('productos', sa.Column('coleccion_id', sa.Integer(), nullable=True))
    op.create_foreign_key(
        'fk_productos_proveedor_id', 'productos', 'proveedores',
        ['proveedor_id'], ['id']
    )
    op.create_foreign_key(
        'fk_productos_temporada_id', 'productos', 'temporadas',
        ['temporada_id'], ['id']
    )
    op.create_foreign_key(
        'fk_productos_coleccion_id', 'productos', 'colecciones',
        ['coleccion_id'], ['id']
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint('fk_productos_coleccion_id', 'productos', type_='foreignkey')
    op.drop_constraint('fk_productos_temporada_id', 'productos', type_='foreignkey')
    op.drop_constraint('fk_productos_proveedor_id', 'productos', type_='foreignkey')
    op.drop_column('productos', 'coleccion_id')
    op.drop_column('productos', 'temporada_id')
    op.drop_column('productos', 'proveedor_id')
