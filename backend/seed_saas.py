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
    db: Session = SessionLocal()
    try:
        print("Creando tablas si no existen...")
        Base.metadata.create_all(bind=engine)

        # Crear planes
        plan_basico = db.query(Plan).filter(Plan.nombre == "Básico").first()
        if not plan_basico:
            plan_basico = Plan(
                nombre="Básico",
                max_sucursales=2,
                permite_ia=False,
                permite_offline=False
            )
            db.add(plan_basico)
            print("Creado plan Básico")
        else:
            print("Plan Básico ya existe")

        plan_profesional = db.query(Plan).filter(Plan.nombre == "Profesional").first()
        if not plan_profesional:
            plan_profesional = Plan(
                nombre="Profesional",
                max_sucursales=10,
                permite_ia=True,
                permite_offline=True
            )
            db.add(plan_profesional)
            print("Creado plan Profesional")
        else:
            print("Plan Profesional ya existe")

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
