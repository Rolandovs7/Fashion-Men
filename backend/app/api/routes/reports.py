# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU29 - Visualizar Dashboard
# CU: CU30 - Generar Reportes
# RF: RF24 - Consultar reportes de ventas e inventario
# ENDPOINT: GET /api/reportes/*
# CAPA: Backend FastAPI (Routes)
# ============================================================
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List

from app.core.dependencies import obtener_db, requerir_rol
from app.services.report_service import ReportService
from app.schemas.reports import (
    DashboardResponse,
    ProductoTopResponse,
    VentaMesResponse,
    VentaMetodoPagoResponse,
    InventarioBajoResponse,
    VentaSucursalResponse,
)

router = APIRouter(tags=["Reportes"])


@router.get("/dashboard", response_model=DashboardResponse)
def dashboard(
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("administrador")),
):
    """
    CU29 - Visualizar Dashboard
    RF24 - KPIs ejecutivos (ventas, pedidos, productos, sucursales).
    """
    service = ReportService(db)
    return service.dashboard_kpis()


@router.get("/productos-top", response_model=List[ProductoTopResponse])
def productos_top(
    limite: int = Query(10, ge=1, le=50),
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("administrador")),
):
    """
    CU30 - Generar Reportes
    RF24 - Top N productos más vendidos.
    """
    service = ReportService(db)
    return service.productos_top(limite)


@router.get("/ventas-por-mes", response_model=List[VentaMesResponse])
def ventas_por_mes(
    meses: int = Query(12, ge=1, le=24),
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("administrador")),
):
    """
    CU30 - Generar Reportes
    RF24 - Serie temporal de ventas por mes.
    """
    service = ReportService(db)
    return service.ventas_por_mes(meses)


@router.get("/ventas-por-metodo-pago", response_model=List[VentaMetodoPagoResponse])
def ventas_por_metodo_pago(
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("administrador")),
):
    """
    CU30 - Generar Reportes
    RF24 - Distribución de ventas por método de pago.
    """
    service = ReportService(db)
    return service.ventas_por_metodo_pago()


@router.get("/inventario-bajo", response_model=List[InventarioBajoResponse])
def inventario_bajo(
    umbral: int = Query(5, ge=0),
    limite: int = Query(20, ge=1, le=100),
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("administrador")),
):
    """
    CU30 - Generar Reportes
    RF24 - Alertas de inventario bajo.
    """
    service = ReportService(db)
    return service.inventario_bajo(umbral, limite)


@router.get("/ventas-por-sucursal", response_model=List[VentaSucursalResponse])
def ventas_por_sucursal(
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("administrador")),
):
    """
    CU30 - Generar Reportes
    RF24 - Ventas agrupadas por sucursal.
    """
    service = ReportService(db)
    return service.ventas_por_sucursal()