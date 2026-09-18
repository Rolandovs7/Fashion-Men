import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface DetallePedido {
  id: number;
  pedido_id: number;
  variante_id: number;
  cantidad: number;
  precio_unitario: number;
  subtotal: number;
}

export interface Pedido {
  id: number;
  usuario_id: number;
  fecha_pedido: string;
  estado: string;
  total: number;
  detalles: DetallePedido[];
}

export interface ItemVentaPresencial {
  variante_id: number;
  cantidad: number;
}

@Injectable({
  providedIn: 'root'
})
export class PedidosService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/pedidos';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listarMisPedidos(estado?: string): Observable<Pedido[]> {
    const query = estado ? `?estado=${estado}` : '';
    return this.http.get<Pedido[]>(
      `${this.apiUrl}${query}`,
      { headers: this.headers() }
    );
  }

  obtener(id: number): Observable<Pedido> {
    return this.http.get<Pedido>(
      `${this.apiUrl}/${id}`,
      { headers: this.headers() }
    );
  }

  crearDesdeCarrito(sucursalId: number): Observable<Pedido> {
    return this.http.post<Pedido>(
      this.apiUrl,
      { sucursal_id: sucursalId },
      { headers: this.headers() }
    );
  }

  cancelar(id: number): Observable<Pedido> {
    return this.http.put<Pedido>(
      `${this.apiUrl}/${id}/cancelar`,
      {},
      { headers: this.headers() }
    );
  }

  // ----- Administración -----
  listarTodos(estado?: string): Observable<Pedido[]> {
    const query = estado ? `?estado=${estado}` : '';
    return this.http.get<Pedido[]>(
      `${this.apiUrl}/admin/todos${query}`,
      { headers: this.headers() }
    );
  }

  cambiarEstado(id: number, nuevoEstado: string, sucursalId?: number): Observable<Pedido> {
    return this.http.put<Pedido>(
      `${this.apiUrl}/${id}/estado`,
      { nuevo_estado: nuevoEstado, sucursal_id: sucursalId ?? null },
      { headers: this.headers() }
    );
  }

  crearVentaPresencial(
    usuarioId: number,
    sucursalId: number,
    metodoPago: string,
    items: ItemVentaPresencial[]
  ): Observable<Pedido> {
    return this.http.post<Pedido>(
      `${this.apiUrl}/venta-presencial`,
      { usuario_id: usuarioId, sucursal_id: sucursalId, metodo_pago: metodoPago, items },
      { headers: this.headers() }
    );
  }
}
