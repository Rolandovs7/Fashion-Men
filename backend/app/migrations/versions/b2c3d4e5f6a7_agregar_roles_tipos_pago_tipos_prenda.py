"""Agregar roles tipos_pago tipos_prenda marcas descuentos

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-09-11 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b2c3d4e5f6a7'
down_revision: Union[str, Sequence[str], None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""

    op.create_table(
        'roles',
        sa.Column('id', sa.Integer(), primary_key=True, index=True),
        sa.Column('nombre', sa.String(length=30), nullable=False, unique=True),
        sa.Column('descripcion', sa.String(length=150), nullable=True),
        sa.Column('activo', sa.Boolean(), nullable=False, server_default=sa.true()),
    )

    op.create_table(
        'tipos_pago',
        sa.Column('id', sa.Integer(), primary_key=True, index=True),
        sa.Column('nombre', sa.String(length=30), nullable=False, unique=True),
        sa.Column('activo', sa.Boolean(), nullable=False, server_default=sa.true()),
    )

    op.create_table(
        'tipos_prenda',
        sa.Column('id', sa.Integer(), primary_key=True, index=True),
        sa.Column('nombre', sa.String(length=100), nullable=False, unique=True),
        sa.Column('descripcion', sa.String(length=255), nullable=True),
        sa.Column('activo', sa.Boolean(), nullable=False, server_default=sa.true()),
    )

    op.create_table(
        'marcas',
        sa.Column('id', sa.Integer(), primary_key=True, index=True),
        sa.Column('nombre', sa.String(length=100), nullable=False, unique=True),
        sa.Column('descripcion', sa.String(length=255), nullable=True),
        sa.Column('activo', sa.Boolean(), nullable=False, server_default=sa.true()),
    )

    op.create_table(
        'descuentos',
        sa.Column('id', sa.Integer(), primary_key=True, index=True),
        sa.Column('nombre', sa.String(length=100), nullable=False),
        sa.Column('porcentaje', sa.Numeric(5, 2), nullable=False),
        sa.Column('fecha_inicio', sa.Date(), nullable=True),
        sa.Column('fecha_fin', sa.Date(), nullable=True),
        sa.Column('activo', sa.Boolean(), nullable=False, server_default=sa.true()),
    )

    op.add_column('productos', sa.Column('tipo_prenda_id', sa.Integer(), nullable=True))
    op.add_column('productos', sa.Column('marca_id', sa.Integer(), nullable=True))
    op.add_column('productos', sa.Column('descuento_id', sa.Integer(), nullable=True))

    op.create_foreign_key(
        'fk_productos_tipo_prenda_id', 'productos', 'tipos_prenda',
        ['tipo_prenda_id'], ['id']
    )
    op.create_foreign_key(
        'fk_productos_marca_id', 'productos', 'marcas',
        ['marca_id'], ['id']
    )
    op.create_foreign_key(
        'fk_productos_descuento_id', 'productos', 'descuentos',
        ['descuento_id'], ['id']
    )

    # Sembrar datos que ya existían como valores fijos en el código,
    # para no romper el comportamiento actual.
    roles_tabla = sa.table(
        'roles',
        sa.column('nombre', sa.String),
        sa.column('descripcion', sa.String),
        sa.column('activo', sa.Boolean),
    )
    op.bulk_insert(roles_tabla, [
        {'nombre': 'cliente', 'descripcion': 'Cliente de la tienda', 'activo': True},
        {'nombre': 'administrador', 'descripcion': 'Administrador de la plataforma', 'activo': True},
    ])

    tipos_pago_tabla = sa.table(
        'tipos_pago',
        sa.column('nombre', sa.String),
        sa.column('activo', sa.Boolean),
    )
    op.bulk_insert(tipos_pago_tabla, [
        {'nombre': 'efectivo', 'activo': True},
        {'nombre': 'tarjeta', 'activo': True},
        {'nombre': 'qr', 'activo': True},
    ])


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint('fk_productos_descuento_id', 'productos', type_='foreignkey')
    op.drop_constraint('fk_productos_marca_id', 'productos', type_='foreignkey')
    op.drop_constraint('fk_productos_tipo_prenda_id', 'productos', type_='foreignkey')
    op.drop_column('productos', 'descuento_id')
    op.drop_column('productos', 'marca_id')
    op.drop_column('productos', 'tipo_prenda_id')
    op.drop_table('descuentos')
    op.drop_table('marcas')
    op.drop_table('tipos_prenda')
    op.drop_table('tipos_pago')
    op.drop_table('roles')
