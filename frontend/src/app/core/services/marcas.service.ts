import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Marca {
  id: number;
  nombre: string;
  descripcion?: string | null;
  activo: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class MarcasService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-hms1.onrender.com/api/marcas';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(soloActivos = false): Observable<Marca[]> {
    return this.http.get<Marca[]>(`${this.apiUrl}?solo_activos=${soloActivos}`);
  }

  crear(nombre: string, descripcion: string | null): Observable<Marca> {
    return this.http.post<Marca>(this.apiUrl, { nombre, descripcion }, { headers: this.headers() });
  }

  eliminar(id: number): Observable<Marca> {
    return this.http.delete<Marca>(`${this.apiUrl}/${id}`, { headers: this.headers() });
  }
}
