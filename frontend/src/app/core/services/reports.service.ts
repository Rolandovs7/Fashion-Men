import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { AuthService } from './auth.service';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU29 - Visualizar Dashboard
// CU: CU30 - Generar Reportes
// RF: RF24 - Consultar reportes de ventas e inventario
// CAPA: Frontend Angular (Service)
// ============================================================

export interface DashboardKpis {
  total_ventas: number;
  total_pedidos: number;
  total_productos: number;
  total_sucursales: number;
  productos_bajo_stock: number;
  clientes_registrados: number;
}

export interface ProductoTop {
  producto_id: number;
  nombre: string;
  total_vendido: number;
  ingresos: number;
}

export interface VentaMes {
  mes: string;
  total: number;
  cantidad_pedidos: number;
}

export interface VentaMetodoPago {
  metodo: string;
  total: number;
  cantidad: number;
}

export interface InventarioBajo {
  variante_id: number;
  producto_id: number;
  producto_nombre: string;
  sucursal: string;
  cantidad: number;
  cantidad_reservada: number;
  cantidad_disponible: number;
}

export interface VentaSucursal {
  sucursal_id: number;
  sucursal: string;
  ciudad: string;
  total_ventas: number;
  cantidad_vendida: number;
}

@Injectable({ providedIn: 'root' })
export class ReportsService {
  private http = inject(HttpClient);
  private auth = inject(AuthService);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/reportes';

  private headers(): HttpHeaders {
    const token = this.auth.getToken() ?? '';
    return new HttpHeaders({ Authorization: `Bearer ${token}` });
  }

  dashboard(): Observable<DashboardKpis> {
    return this.http.get<DashboardKpis>(`${this.apiUrl}/dashboard`, {
      headers: this.headers(),
    });
  }

  productosTop(limite = 10): Observable<ProductoTop[]> {
    return this.http.get<ProductoTop[]>(
      `${this.apiUrl}/productos-top?limite=${limite}`,
      { headers: this.headers() }
    );
  }

  ventasPorMes(meses = 12): Observable<VentaMes[]> {
    return this.http.get<VentaMes[]>(
      `${this.apiUrl}/ventas-por-mes?meses=${meses}`,
      { headers: this.headers() }
    );
  }

  ventasPorMetodoPago(): Observable<VentaMetodoPago[]> {
    return this.http.get<VentaMetodoPago[]>(
      `${this.apiUrl}/ventas-por-metodo-pago`,
      { headers: this.headers() }
    );
  }

  inventarioBajo(umbral = 5, limite = 20): Observable<InventarioBajo[]> {
    return this.http.get<InventarioBajo[]>(
      `${this.apiUrl}/inventario-bajo?umbral=${umbral}&limite=${limite}`,
      { headers: this.headers() }
    );
  }

  ventasPorSucursal(): Observable<VentaSucursal[]> {
    return this.http.get<VentaSucursal[]>(
      `${this.apiUrl}/ventas-por-sucursal`,
      { headers: this.headers() }
    );
  }
}