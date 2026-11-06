import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.core.security import obtener_password_hash
from app.models.saas import Empresa
from app.models.user import Usuario


def asegurar_usuario(db, *, nombre, apellido, email, password, rol, empresa_id=None):
    usuario = db.query(Usuario).filter(Usuario.email == email).first()
    if usuario:
        actualizado = False
        if usuario.rol != rol:
            usuario.rol = rol
            actualizado = True
        if not usuario.activo:
            usuario.activo = True
            actualizado = True
        if empresa_id is not None and usuario.empresa_id != empresa_id:
            usuario.empresa_id = empresa_id
            actualizado = True
        # Asegurar contraseña conocida para seed/admin
        usuario.password_hash = obtener_password_hash(password)
        actualizado = True
        if actualizado:
            db.commit()
            db.refresh(usuario)
            print(f"Actualizado: {email} (rol={usuario.rol}, empresa_id={usuario.empresa_id})")
        else:
            print(f"Sin cambios: {email}")
        return usuario

    usuario = Usuario(
        nombre=nombre,
        apellido=apellido,
        email=email,
        password_hash=obtener_password_hash(password),
        rol=rol,
        activo=True,
        empresa_id=empresa_id,
    )
    db.add(usuario)
    db.commit()
    db.refresh(usuario)
    print(f"Creado: {email} (rol={usuario.rol}, empresa_id={usuario.empresa_id})")
    return usuario


def crear_admin():
    db = SessionLocal()
    try:
        # Superadmin de la plataforma (dueño)
        asegurar_usuario(
            db,
            nombre="Rolando",
            apellido="Velasco",
            email="rolando.vsoliz@gmail.com",
            password="Rolando2026@",
            rol="superadmin",
            empresa_id=None,
        )

        # Administrador de empresa MenStyle
        empresa_menstyle = db.query(Empresa).filter(Empresa.nombre == "MenStyle").first()
        if not empresa_menstyle:
            print("ADVERTENCIA: Empresa 'MenStyle' no encontrada. Ejecute seed_saas.py primero. Creando usuario Jimena sin empresa_id.")
            empresa_id = None
        else:
            empresa_id = empresa_menstyle.id

        asegurar_usuario(
            db,
            nombre="Jimena",
            apellido="Jahuira",
            email="jimenajahuira26@gmail.com",
            password="Jimena2026@",
            rol="administrador",
            empresa_id=empresa_id,
        )

        print("\nSeed admin completado.")
        print("- SuperAdmin: rolando.vsoliz@gmail.com / Rolando2026@ (rol=superadmin)")
        print("- Admin MenStyle: jimenajahuira26@gmail.com / Jimena2026@ (rol=administrador)")
    finally:
        db.close()


if __name__ == "__main__":
    crear_admin()
