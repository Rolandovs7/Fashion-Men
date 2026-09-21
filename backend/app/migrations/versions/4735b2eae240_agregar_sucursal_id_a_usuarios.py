"""agregar_sucursal_id_a_usuarios

Revision ID: 4735b2eae240
Revises: c1ca86f7ee94
Create Date: 2026-09-21 19:33:26.597915

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '4735b2eae240'
down_revision: Union[str, Sequence[str], None] = 'c1ca86f7ee94'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'usuarios',
        sa.Column('sucursal_id', sa.Integer(), nullable=True)
    )
    op.create_foreign_key(
        'fk_usuarios_sucursal',
        'usuarios', 'sucursales',
        ['sucursal_id'], ['id']
    )
    op.create_index(
        'ix_usuarios_sucursal_id',
        'usuarios', ['sucursal_id']
    )
    """Upgrade schema."""
    pass


def downgrade() -> None:
    op.drop_index('ix_usuarios_sucursal_id', table_name='usuarios')
    op.drop_constraint('fk_usuarios_sucursal', 'usuarios', type_='foreignkey')
    op.drop_column('usuarios', 'sucursal_id')
    """Downgrade schema."""
    pass
