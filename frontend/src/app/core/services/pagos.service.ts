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
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/pagos';

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
    // ============================================================
  // RF19 — Stripe
  // ============================================================

  obtenerConfigStripe(): Observable<{ publishable_key: string; modo: string }> {
    return this.http.get<{ publishable_key: string; modo: string }>(
      `${this.apiUrl}/stripe/config`,
      { headers: this.headers() }
    );
  }

  crearStripeIntent(pedidoId: number, moneda = 'usd'): Observable<{
    client_secret: string;
    payment_intent_id: string;
    monto: number;
    moneda: string;
    publishable_key: string;
  }> {
    return this.http.post<any>(
      `${this.apiUrl}/stripe/intent`,
      { pedido_id: pedidoId, moneda },
      { headers: this.headers() }
    );
  }

  confirmarStripePago(paymentIntentId: string): Observable<{
    payment_intent_id: string;
    estado: string;
    monto: number;
    moneda: string;
  }> {
    return this.http.post<any>(
      `${this.apiUrl}/stripe/confirm`,
      { payment_intent_id: paymentIntentId },
      { headers: this.headers() }
    );
  }
}
