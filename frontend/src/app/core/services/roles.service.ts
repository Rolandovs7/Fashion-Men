import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Rol {
  id: number;
  nombre: string;
  descripcion?: string | null;
  activo: boolean;
}

export interface RolCrear {
  nombre: string;
  descripcion?: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class RolesService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-hms1.onrender.com/api/roles';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(soloActivos = true): Observable<Rol[]> {
    return this.http.get<Rol[]>(`${this.apiUrl}?solo_activos=${soloActivos}`);
  }

  crear(datos: RolCrear): Observable<Rol> {
    return this.http.post<Rol>(this.apiUrl, datos, { headers: this.headers() });
  }

  eliminar(id: number): Observable<Rol> {
    return this.http.delete<Rol>(`${this.apiUrl}/${id}`, { headers: this.headers() });
  }
}
