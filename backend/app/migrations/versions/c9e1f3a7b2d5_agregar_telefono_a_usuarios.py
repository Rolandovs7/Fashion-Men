"""Agregar teléfono de contacto a usuarios

Soporte para el panel de usuarios por empresa (CU04):
- usuarios.telefono: teléfono de contacto del cliente (nullable).

Revision ID: c9e1f3a7b2d5
Revises: a7c4e9f2d1b8
Create Date: 2026-11-11
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = 'c9e1f3a7b2d5'
down_revision: Union[str, Sequence[str], None] = 'a7c4e9f2d1b8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table('usuarios') as batch_op:
        batch_op.add_column(sa.Column('telefono', sa.String(length=30), nullable=True))


def downgrade() -> None:
    with op.batch_alter_table('usuarios') as batch_op:
        batch_op.drop_column('telefono')
