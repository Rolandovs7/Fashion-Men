import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { map, tap } from 'rxjs/operators';

export interface Sucursal {
  id: number;
  nombre: string;
  direccion: string;
  ciudad: string;
  telefono?: string | null;
  activo: boolean;
}

export interface SucursalCrear {
  nombre: string;
  direccion: string;
  ciudad: string;
  telefono?: string | null;
  activo?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class SucursalesService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/sucursales';
  private cacheKey = 'menstyle_cache_sucursales';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(soloActivos = true): Observable<Sucursal[]> {
    if (!navigator.onLine) {
      try {
        const cached = localStorage.getItem(this.cacheKey);
        if (cached) {
          const data = JSON.parse(cached) as Sucursal[];
          return of(soloActivos ? data.filter(d => d.activo) : data);
        }
      } catch {
        // ignore
      }
      return of([]);
    }
    return this.http.get<Sucursal[]>(
      `${this.apiUrl}?solo_activos=${soloActivos}`
    ).pipe(
      tap((data) => {
        try {
          localStorage.setItem(this.cacheKey, JSON.stringify(data));
        } catch {
          // ignore
        }
      })
    );
  }

  crear(datos: SucursalCrear): Observable<Sucursal> {
    return this.http.post<Sucursal>(
      this.apiUrl,
      datos,
      { headers: this.headers() }
    );
  }

  actualizar(id: number, datos: SucursalCrear): Observable<Sucursal> {
    return this.http.put<Sucursal>(
      `${this.apiUrl}/${id}`,
      datos,
      { headers: this.headers() }
    );
  }

  eliminar(id: number): Observable<Sucursal> {
    return this.http.delete<Sucursal>(
      `${this.apiUrl}/${id}`,
      { headers: this.headers() }
    );
  }
}
