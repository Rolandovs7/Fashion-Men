# ============================================================
# TRAZABILIDAD MENSTYLE
# CU: CU29 - Visualizar Dashboard
# CU: CU30 - Generar Reportes
# RF: RF24 - Consultar reportes de ventas e inventario
# ENDPOINT: GET /api/reportes/*
# CAPA: Backend FastAPI (Routes)
# ============================================================
"""
[Segundo Parcial] CU22 - Exportación de reportes
[Segundo Parcial] CU25 - Dashboard analítico
[Segundo Parcial] RNF02 - Aislamiento por empresa
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List

from app.core.dependencies import obtener_db, requerir_rol, get_current_empresa_id, requerir_suscripcion_vigente
from app.services.report_service import ReportService
from app.schemas.reports import (
    DashboardResponse,
    ProductoTopResponse,
    VentaMesResponse,
    VentaMetodoPagoResponse,
    InventarioBajoResponse,
    VentaSucursalResponse,
    VentaEmpresaResponse,
)

router = APIRouter(tags=["Reportes"])


@router.get("/dashboard", response_model=DashboardResponse)
def dashboard(
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id),
    _suscripcion=Depends(requerir_suscripcion_vigente),
):
    """
    [Segundo Parcial] CU25 - Dashboard analítico
    CU29 - Visualizar Dashboard
    [Segundo Parcial] RNF02 - Aislamiento por empresa
    RF24 - KPIs ejecutivos (ventas, pedidos, productos, sucursales).
    """
    service = ReportService(db)
    return service.dashboard_kpis(empresa_id)


@router.get("/productos-top", response_model=List[ProductoTopResponse])
def productos_top(
    limite: int = Query(10, ge=1, le=50),
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id),
    _suscripcion=Depends(requerir_suscripcion_vigente),
):
    """
    [Segundo Parcial] CU22 - Exportación de reportes
    CU30 - Generar Reportes
    [Segundo Parcial] RNF02 - Aislamiento por empresa
    RF24 - Top N productos más vendidos.
    """
    service = ReportService(db)
    return service.productos_top(limite, empresa_id)


@router.get("/ventas-por-mes", response_model=List[VentaMesResponse])
def ventas_por_mes(
    meses: int = Query(12, ge=1, le=24),
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id),
    _suscripcion=Depends(requerir_suscripcion_vigente),
):
    """
    [Segundo Parcial] CU25 - Dashboard analítico
    CU30 - Generar Reportes
    [Segundo Parcial] RNF02 - Aislamiento por empresa
    RF24 - Serie temporal de ventas por mes.
    """
    service = ReportService(db)
    return service.ventas_por_mes(meses, empresa_id)


@router.get("/ventas-por-metodo-pago", response_model=List[VentaMetodoPagoResponse])
def ventas_por_metodo_pago(
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id),
    _suscripcion=Depends(requerir_suscripcion_vigente),
):
    """
    CU30 - Generar Reportes
    [Segundo Parcial] RNF02 - Aislamiento por empresa
    RF24 - Distribución de ventas por método de pago.
    """
    service = ReportService(db)
    return service.ventas_por_metodo_pago(empresa_id)


@router.get("/inventario-bajo", response_model=List[InventarioBajoResponse])
def inventario_bajo(
    umbral: int = Query(5, ge=0),
    limite: int = Query(20, ge=1, le=100),
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id),
    _suscripcion=Depends(requerir_suscripcion_vigente),
):
    """
    CU30 - Generar Reportes
    [Segundo Parcial] RNF02 - Aislamiento por empresa
    RF24 - Alertas de inventario bajo.
    """
    service = ReportService(db)
    return service.inventario_bajo(umbral, limite, empresa_id)


@router.get("/ventas-por-sucursal", response_model=List[VentaSucursalResponse])
def ventas_por_sucursal(
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("administrador")),
    empresa_id: int = Depends(get_current_empresa_id),
    _suscripcion=Depends(requerir_suscripcion_vigente),
):
    """
    [Segundo Parcial] CU25 - Dashboard analítico
    CU30 - Generar Reportes
    [Segundo Parcial] RNF02 - Aislamiento por empresa
    RF24 - Ventas agrupadas por sucursal.
    """
    service = ReportService(db)
    return service.ventas_por_sucursal(empresa_id)


@router.get("/ventas-por-empresa", response_model=List[VentaEmpresaResponse])
def ventas_por_empresa(
    db: Session = Depends(obtener_db),
    usuario=Depends(requerir_rol("superadmin")),
):
    """
    CU29 - Visualizar Dashboard (SuperAdmin)
    CU30 - Generar Reportes
    RF24 - Ventas agrupadas por empresa (todas las empresas del SaaS).
    Alimenta el gráfico de torta "Ventas por Empresa" del Dashboard
    del SuperAdmin (MenStyle vs Avenor vs ...). Solo SuperAdmin.
    """
    service = ReportService(db)
    return service.ventas_por_empresa()