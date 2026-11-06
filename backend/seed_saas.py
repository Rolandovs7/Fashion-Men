"""
[Segundo Parcial] CU01 - Registrar empresa y contratar plan
[Segundo Parcial] CU02 - Suscripción
[Segundo Parcial] RF01 - Gestión Multitenant y Empresas
Consumido por: Frontend (Admin)
"""
import os
import sys
from datetime import datetime, timezone

from sqlalchemy.orm import Session

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal, engine
from app.core.database import Base
from app.models.saas import Empresa, Plan, Suscripcion
from app.models.user import Usuario
from app.models.branch import Sucursal


def seed_saas():
    """
    [Segundo Parcial] CU01 - Registrar empresa y contratar plan
    [Segundo Parcial] CU02 - Suscripción
    """

    db: Session = SessionLocal()
    try:
        print("Creando tablas si no existen...")
        Base.metadata.create_all(bind=engine)

        # Crear/actualizar planes (3 tiers)
        plan_basico = db.query(Plan).filter(Plan.nombre == "Básico").first()
        if not plan_basico:
            plan_basico = Plan(
                nombre="Básico",
                max_sucursales=2,
                permite_ia=False,
                permite_offline=False,
                precio_mensual=0,
                descripcion="Ideal para tiendas pequeñas que inician.",
            )
            db.add(plan_basico)
            print("Creado plan Básico")
        else:
            plan_basico.max_sucursales = 2
            plan_basico.permite_ia = False
            plan_basico.permite_offline = False
            plan_basico.precio_mensual = 0
            plan_basico.descripcion = "Ideal para tiendas pequeñas que inician."
            print("Plan Básico actualizado")

        plan_emprendedor = db.query(Plan).filter(Plan.nombre == "Emprendedor").first()
        if not plan_emprendedor:
            plan_emprendedor = Plan(
                nombre="Emprendedor",
                max_sucursales=5,
                permite_ia=False,
                permite_offline=False,
                precio_mensual=29,
                descripcion="Para negocios en crecimiento que necesitan más control.",
            )
            db.add(plan_emprendedor)
            print("Creado plan Emprendedor")
        else:
            plan_emprendedor.max_sucursales = 5
            plan_emprendedor.permite_ia = False
            plan_emprendedor.permite_offline = False
            plan_emprendedor.precio_mensual = 29
            plan_emprendedor.descripcion = "Para negocios en crecimiento que necesitan más control."
            print("Plan Emprendedor actualizado")

        plan_profesional = db.query(Plan).filter(Plan.nombre == "Profesional").first()
        if not plan_profesional:
            plan_profesional = Plan(
                nombre="Profesional",
                max_sucursales=10,
                permite_ia=True,
                permite_offline=True,
                precio_mensual=59,
                descripcion="Potencia total con Inteligencia Artificial y reportes avanzados.",
            )
            db.add(plan_profesional)
            print("Creado plan Profesional")
        else:
            plan_profesional.max_sucursales = 10
            plan_profesional.permite_ia = True
            plan_profesional.permite_offline = True
            plan_profesional.precio_mensual = 59
            plan_profesional.descripcion = "Potencia total con Inteligencia Artificial y reportes avanzados."
            print("Plan Profesional actualizado")

        db.flush()

        # Crear empresas
        empresa_menstyle = db.query(Empresa).filter(Empresa.nombre == "MenStyle").first()
        if not empresa_menstyle:
            empresa_menstyle = Empresa(nombre="MenStyle", activo=True)
            db.add(empresa_menstyle)
            print("Creada empresa MenStyle")
        else:
            print("Empresa MenStyle ya existe")

        empresa_fashiontest = db.query(Empresa).filter(Empresa.nombre == "FashionTest").first()
        if not empresa_fashiontest:
            empresa_fashiontest = Empresa(nombre="FashionTest", activo=True)
            db.add(empresa_fashiontest)
            print("Creada empresa FashionTest")
        else:
            print("Empresa FashionTest ya existe")

        db.flush()

        # Asignar suscripciones
        sub_menstyle = db.query(Suscripcion).filter(Suscripcion.empresa_id == empresa_menstyle.id).first()
        if not sub_menstyle:
            sub_menstyle = Suscripcion(
                empresa_id=empresa_menstyle.id,
                plan_id=plan_profesional.id,
                fecha_inicio=datetime.now(timezone.utc),
                estado="activo"
            )
            db.add(sub_menstyle)
            print("Creada suscripción Profesional para MenStyle")
        else:
            print("Suscripción para MenStyle ya existe")

        sub_fashion = db.query(Suscripcion).filter(Suscripcion.empresa_id == empresa_fashiontest.id).first()
        if not sub_fashion:
            sub_fashion = Suscripcion(
                empresa_id=empresa_fashiontest.id,
                plan_id=plan_basico.id,
                fecha_inicio=datetime.now(timezone.utc),
                estado="activo"
            )
            db.add(sub_fashion)
            print("Creada suscripción Básico para FashionTest")
        else:
            print("Suscripción para FashionTest ya existe")

        # Asignar empresa a usuarios y sucursales actuales (MenStyle)
        usuarios_actualizados = db.query(Usuario).filter(Usuario.empresa_id.is_(None)).update(
            {"empresa_id": empresa_menstyle.id}
        )
        print(f"Usuarios actualizados con empresa_id MenStyle: {usuarios_actualizados}")

        sucursales_actualizadas = db.query(Sucursal).filter(Sucursal.empresa_id.is_(None)).update(
            {"empresa_id": empresa_menstyle.id}
        )
        print(f"Sucursales actualizadas con empresa_id MenStyle: {sucursales_actualizadas}")

        db.commit()
        print("Seed SaaS completado exitosamente")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_saas()
