"""report_indexes_producto_variante_inventario

Revision ID: 1487318890a5
Revises: b5d3dbc49ff5
Create Date: 2026-11-03 11:31:50.900991

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '1487318890a5'
down_revision: Union[str, Sequence[str], None] = 'b5d3dbc49ff5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_index(op.f('ix_producto_variantes_producto_id'), 'producto_variantes', ['producto_id'], unique=False)
    op.create_index(op.f('ix_inventarios_variante_id'), 'inventarios', ['variante_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_inventarios_variante_id'), table_name='inventarios')
    op.drop_index(op.f('ix_producto_variantes_producto_id'), table_name='producto_variantes')
