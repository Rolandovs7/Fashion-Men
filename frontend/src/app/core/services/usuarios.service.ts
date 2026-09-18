import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Usuario {
  id: number;
  nombre: string;
  apellido: string;
  email: string;
  activo: boolean;
  rol: string;
}

export interface UsuarioActualizar {
  nombre: string;
  apellido: string;
  email: string;
  activo: boolean;
  rol: string;
}

export interface UsuarioCrear {
  nombre: string;
  apellido: string;
  email: string;
  password: string;
  rol: string;
}

@Injectable({
  providedIn: 'root'
})
export class UsuariosService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/usuarios';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  listar(): Observable<Usuario[]> {
    return this.http.get<Usuario[]>(
      this.apiUrl,
      { headers: this.headers() }
    );
  }

  crear(datos: UsuarioCrear): Observable<Usuario> {
    return this.http.post<Usuario>(
      this.apiUrl,
      datos,
      { headers: this.headers() }
    );
  }

  actualizar(
    id: number,
    datos: UsuarioActualizar
  ): Observable<Usuario> {
    return this.http.put<Usuario>(
      `${this.apiUrl}/${id}`,
      datos,
      { headers: this.headers() }
    );
  }

  eliminar(id: number): Observable<any> {
    return this.http.delete(
      `${this.apiUrl}/${id}`,
      { headers: this.headers() }
    );
  }
}
