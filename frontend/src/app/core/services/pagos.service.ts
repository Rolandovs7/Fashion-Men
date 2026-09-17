import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Pago {
  id: number;
  pedido_id: number;
  metodo: string;
  monto: number;
  estado: string;
  referencia?: string | null;
  fecha_pago?: string | null;
}

export interface PagoCrear {
  pedido_id: number;
  metodo: string;
  monto: number;
  referencia?: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class PagosService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-hms1.onrender.com/api/pagos';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  registrarPago(datos: PagoCrear): Observable<Pago> {
    return this.http.post<Pago>(
      this.apiUrl,
      datos,
      { headers: this.headers() }
    );
  }

  listarPorPedido(pedidoId: number): Observable<Pago[]> {
    return this.http.get<Pago[]>(
      `${this.apiUrl}/pedido/${pedidoId}`,
      { headers: this.headers() }
    );
  }
}
