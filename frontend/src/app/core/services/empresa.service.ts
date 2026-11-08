import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface EmpresaCrearRequest {
  nombre_empresa: string;
  plan_id: number;
  admin_nombre?: string | null;
  admin_apellido?: string | null;
  admin_email?: string | null;
  admin_password?: string | null;
}

export interface EmpresaCrearResponse {
  empresa_id: number;
  empresa_nombre: string;
  plan_id: number;
  plan_nombre: string;
  suscripcion_id: number;
  admin_usuario_id?: number | null;
  mensaje: string;
}

export interface EmpresaListado {
  id: number;
  nombre: string;
  fecha_registro?: string | null;
  plan_actual?: string | null;
  activo?: boolean;
}

@Injectable({ providedIn: 'root' })
export class EmpresaService {
  private http = inject(HttpClient);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/empresas';

  private headers(): HttpHeaders {
    const token = localStorage.getItem('access_token');
    return new HttpHeaders({
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    });
  }

  listarEmpresas(): Observable<EmpresaListado[]> {
    return this.http.get<EmpresaListado[]>(this.apiUrl, { headers: this.headers() });
  }

  crearEmpresa(datos: EmpresaCrearRequest): Observable<EmpresaCrearResponse> {
    return this.http.post<EmpresaCrearResponse>(this.apiUrl, datos, { headers: this.headers() });
  }
}
