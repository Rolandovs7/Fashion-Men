import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { BehaviorSubject, Observable, tap } from 'rxjs';

export interface DetalleCarrito {
  id: number;
  carrito_id: number;
  variante_id: number;
  cantidad: number;
}

export interface Carrito {
  id: number;
  usuario_id: number;
  detalles: DetalleCarrito[];
}

@Injectable({
  providedIn: 'root'
})
export class CarritoService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-hms1.onrender.com/api/carrito';

  // Contador reactivo para el badge del carrito en el header
  private contadorSubject = new BehaviorSubject<number>(0);
  contador$ = this.contadorSubject.asObservable();

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  private actualizarContador(carrito: Carrito): void {
    const total = carrito.detalles.reduce((acc, d) => acc + d.cantidad, 0);
    this.contadorSubject.next(total);
  }

  obtener(): Observable<Carrito> {
    return this.http.get<Carrito>(
      this.apiUrl,
      { headers: this.headers() }
    ).pipe(tap(c => this.actualizarContador(c)));
  }

  agregarItem(varianteId: number, cantidad: number): Observable<Carrito> {
    return this.http.post<Carrito>(
      `${this.apiUrl}/items`,
      { variante_id: varianteId, cantidad },
      { headers: this.headers() }
    ).pipe(tap(c => this.actualizarContador(c)));
  }

  actualizarItem(detalleId: number, cantidad: number): Observable<Carrito> {
    return this.http.put<Carrito>(
      `${this.apiUrl}/items/${detalleId}`,
      { cantidad },
      { headers: this.headers() }
    ).pipe(tap(c => this.actualizarContador(c)));
  }

  eliminarItem(detalleId: number): Observable<Carrito> {
    return this.http.delete<Carrito>(
      `${this.apiUrl}/items/${detalleId}`,
      { headers: this.headers() }
    ).pipe(tap(c => this.actualizarContador(c)));
  }

  vaciar(): Observable<Carrito> {
    return this.http.delete<Carrito>(
      this.apiUrl,
      { headers: this.headers() }
    ).pipe(tap(c => this.actualizarContador(c)));
  }
}
