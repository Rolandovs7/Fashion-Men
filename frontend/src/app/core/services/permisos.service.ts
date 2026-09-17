import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Permiso {
  id: number;
  nombre: string;
  descripcion: string;
  activo: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class PermisosService {

  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-hms1.onrender.com/api/permisos';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(): Observable<Permiso[]> {
    return this.http.get<Permiso[]>(
      this.apiUrl,
      { headers: this.headers() }
    );
  }

  porRol(rol: string): Observable<Permiso[]> {
    return this.http.get<Permiso[]>(
      `${this.apiUrl}/rol/${rol}`,
      { headers: this.headers() }
    );
  }

  asignar(rol: string, permiso_id: number): Observable<any> {
    return this.http.post(
      `${this.apiUrl}/asignar`,
      {
        rol: rol,
        permiso_id: permiso_id
      },
      { headers: this.headers() }
    );
  }

  quitar(rol: string, permiso_id: number): Observable<any> {
    return this.http.delete(
      `${this.apiUrl}/quitar/${rol}/${permiso_id}`,
      { headers: this.headers() }
    );
  }
}