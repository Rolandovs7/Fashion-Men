import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

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
}

@Injectable({
  providedIn: 'root'
})
export class SucursalesService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-hms1.onrender.com/api/sucursales';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(soloActivos = true): Observable<Sucursal[]> {
    return this.http.get<Sucursal[]>(
      `${this.apiUrl}?solo_activos=${soloActivos}`
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
