from datetime import datetime, timezone, timezone  # ✅ Importar al inicio
from typing import List
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_

from app.models.notification import Notificacion
from app.models.user import Usuario


def crear_notificacion(
    db: Session,
    usuario_id: int,
    titulo: str,
    mensaje: str
) -> Notificacion:
    nueva_notificacion = Notificacion(
        usuario_id=usuario_id,
        titulo=titulo,
        mensaje=mensaje,
        leida=False,
        fecha_creacion=datetime.now(timezone.utc)  # ✅ Ahora sí funciona
    )

    db.add(nueva_notificacion)
    # No hace commit por sí solo para permitir que se incluya en la transacción principal si es necesario.
    return nueva_notificacion


def listar_notificaciones(
    db: Session,
    usuario_id: int,
    solo_no_leidas: bool = False
) -> List[Notificacion]:
    query = db.query(Notificacion).filter(
        Notificacion.usuario_id == usuario_id
    )

    if solo_no_leidas:
        query = query.filter(Notificacion.leida.is_(False))

    return query.order_by(Notificacion.fecha_creacion.desc()).all()


def marcar_como_leida(
    db: Session,
    usuario_id: int,
    notificacion_id: int
) -> Notificacion:
    notificacion = db.query(Notificacion).filter(
        Notificacion.id == notificacion_id,
        Notificacion.usuario_id == usuario_id
    ).first()

    if not notificacion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notificación no encontrada"
        )

    notificacion.leida = True
    db.commit()
    db.refresh(notificacion)

    return notificacion

def notificar_nueva_reserva(
    db: Session,
    reserva,
    sucursal,
    cliente,
) -> int:
    """
    RF11 — Notifica a encargados de la sucursal + admins de una nueva reserva.
    Retorna la cantidad de notificaciones creadas.
    """
    destinatarios = db.query(Usuario).filter(
        Usuario.activo.is_(True),
        or_(
            Usuario.rol == "administrador",
            and_(
                Usuario.rol == "encargado",
                Usuario.sucursal_id == sucursal.id,
            )
        )
    ).all()

    titulo = f"Nueva reserva en {sucursal.nombre}"
    mensaje = (
        f"{cliente.nombre} {cliente.apellido} reservó "
        f"{len(reserva.detalles)} producto(s). "
        f"Reserva #{reserva.id}. Revisá el panel de reservas."
    )

    for u in destinatarios:
        crear_notificacion(db, u.id, titulo, mensaje)

    return len(destinatarios)
