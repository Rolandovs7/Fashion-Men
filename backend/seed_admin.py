from app.core.database import SessionLocal
from app.core.security import obtener_password_hash
from app.models.user import Usuario


def crear_admin():
    db = SessionLocal()

    try:
        email = "rolando@gmail.com"

        usuario = db.query(Usuario).filter(
            Usuario.email == email
        ).first()

        if usuario:
            print(f"El usuario {email} ya existe.")

            if usuario.rol != "administrador":
                usuario.rol = "administrador"
                usuario.activo = True
                db.commit()
                print("Usuario actualizado a administrador.")
            else:
                print("El usuario ya es administrador.")

            return

        admin = Usuario(
            nombre="Rolando",
            apellido="Velasco",
            email=email,
            password_hash=obtener_password_hash("123456"),
            rol="administrador",
            activo=True
        )

        db.add(admin)
        db.commit()
        db.refresh(admin)

        print("Administrador creado correctamente.")
        print(f"ID: {admin.id}")
        print(f"Email: {admin.email}")
        print(f"Rol: {admin.rol}")

    finally:
        db.close()


if __name__ == "__main__":
    crear_admin()
