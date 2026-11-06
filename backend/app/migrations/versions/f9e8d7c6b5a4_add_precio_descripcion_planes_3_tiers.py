"""add precio_mensual and descripcion to planes, seed 3 tiers

Revision ID: f9e8d7c6b5a4
Revises: 1487318890a5
Create Date: 2026-11-06 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f9e8d7c6b5a4'
down_revision: Union[str, Sequence[str], None] = '1487318890a5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('planes', sa.Column('precio_mensual', sa.Numeric(10, 2), nullable=False, server_default='0'))
    op.add_column('planes', sa.Column('descripcion', sa.String(length=255), nullable=True))

    # Seed/actualizar 3 planes comerciales
    op.execute(
        """
        UPDATE planes SET max_sucursales=2, permite_ia=false, permite_offline=false,
            precio_mensual=0, descripcion='Ideal para tiendas pequeñas que inician.'
        WHERE nombre='Básico'
        """
    )
    op.execute(
        """
        UPDATE planes SET max_sucursales=10, permite_ia=true, permite_offline=true,
            precio_mensual=59, descripcion='Potencia total con Inteligencia Artificial y reportes avanzados.'
        WHERE nombre='Profesional'
        """
    )
    op.execute(
        """
        INSERT INTO planes (nombre, max_sucursales, permite_ia, permite_offline, precio_mensual, descripcion)
        SELECT 'Emprendedor', 5, false, false, 29, 'Para negocios en crecimiento que necesitan más control.'
        WHERE NOT EXISTS (SELECT 1 FROM planes WHERE nombre='Emprendedor')
        """
    )
    # Por si Emprendedor ya existiera (raro), actualizarlo
    op.execute(
        """
        UPDATE planes SET max_sucursales=5, permite_ia=false, permite_offline=false,
            precio_mensual=29, descripcion='Para negocios en crecimiento que necesitan más control.'
        WHERE nombre='Emprendedor'
        """
    )


def downgrade() -> None:
    op.drop_column('planes', 'descripcion')
    op.drop_column('planes', 'precio_mensual')
