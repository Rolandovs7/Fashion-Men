import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Proveedor {
  id: number;
  nombre: string;
  contacto?: string | null;
  telefono?: string | null;
  email?: string | null;
  direccion?: string | null;
  activo: boolean;
}

export interface ProveedorCrear {
  nombre: string;
  contacto?: string | null;
  telefono?: string | null;
  email?: string | null;
  direccion?: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class ProveedoresService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/proveedores';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(soloActivos = true): Observable<Proveedor[]> {
    return this.http.get<Proveedor[]>(
      `${this.apiUrl}?solo_activos=${soloActivos}`,
      { headers: this.headers() }
    );
  }

  crear(datos: ProveedorCrear): Observable<Proveedor> {
    return this.http.post<Proveedor>(
      this.apiUrl,
      datos,
      { headers: this.headers() }
    );
  }

  eliminar(id: number): Observable<Proveedor> {
    return this.http.delete<Proveedor>(
      `${this.apiUrl}/${id}`,
      { headers: this.headers() }
    );
  }
}
