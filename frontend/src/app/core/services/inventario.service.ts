import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Inventario {
  id: number;
  variante_id: number;
  sucursal_id: number;
  cantidad: number;
  cantidad_reservada: number;
}

export interface InventarioCrear {
  variante_id: number;
  sucursal_id: number;
  cantidad: number;
  cantidad_reservada?: number;
}

export interface InventarioActualizar {
  cantidad?: number;
  cantidad_reservada?: number;
}

@Injectable({
  providedIn: 'root'
})
export class InventarioService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/inventario';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(sucursalId?: number, varianteId?: number): Observable<Inventario[]> {
    const params = new URLSearchParams();
    if (sucursalId) params.set('sucursal_id', String(sucursalId));
    if (varianteId) params.set('variante_id', String(varianteId));
    const query = params.toString() ? `?${params.toString()}` : '';

    return this.http.get<Inventario[]>(`${this.apiUrl}${query}`);
  }

  crear(datos: InventarioCrear): Observable<Inventario> {
    return this.http.post<Inventario>(this.apiUrl, datos, { headers: this.headers() });
  }

  actualizar(id: number, datos: InventarioActualizar): Observable<Inventario> {
    return this.http.put<Inventario>(`${this.apiUrl}/${id}`, datos, { headers: this.headers() });
  }

  eliminar(id: number): Observable<Inventario> {
    return this.http.delete<Inventario>(`${this.apiUrl}/${id}`, { headers: this.headers() });
  }
}
