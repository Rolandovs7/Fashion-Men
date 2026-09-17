#!/bin/bash

mkdir -p src/app/core/services
mkdir -p src/app/pages/usuarios

cat > src/app/core/services/usuarios.service.ts <<'EOF'
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

@Injectable({
  providedIn: 'root'
})
export class UsuariosService {
  private http = inject(HttpClient);
  private apiUrl = 'http://127.0.0.1:8000/api/usuarios';

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
EOF


cat > src/app/pages/usuarios/usuarios.ts <<'EOF'
import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import {
  UsuariosService,
  Usuario,
  UsuarioActualizar
} from '../../core/services/usuarios.service';

@Component({
  selector: 'app-usuarios',
  imports: [CommonModule, FormsModule],
  templateUrl: './usuarios.html',
  styleUrl: './usuarios.css'
})
export class Usuarios implements OnInit {
  private usuariosService = inject(UsuariosService);

  usuarios: Usuario[] = [];
  usuarioEditando: Usuario | null = null;
  error = '';
  mensaje = '';
  cargando = false;

  ngOnInit(): void {
    this.cargarUsuarios();
  }

  cargarUsuarios(): void {
    this.cargando = true;
    this.error = '';

    this.usuariosService.listar().subscribe({
      next: (usuarios) => {
        this.usuarios = usuarios;
        this.cargando = false;
      },
      error: (error) => {
        this.cargando = false;

        if (error.status === 401) {
          this.error = 'Sesión no válida. Inicia sesión nuevamente.';
        } else if (error.status === 403) {
          this.error = 'No tienes permisos de administrador.';
        } else {
          this.error = 'No se pudieron cargar los usuarios.';
        }
      }
    });
  }

  editar(usuario: Usuario): void {
    this.usuarioEditando = { ...usuario };
    this.error = '';
    this.mensaje = '';
  }

  cancelarEdicion(): void {
    this.usuarioEditando = null;
  }

  guardar(): void {
    if (!this.usuarioEditando) {
      return;
    }

    const datos: UsuarioActualizar = {
      nombre: this.usuarioEditando.nombre,
      apellido: this.usuarioEditando.apellido,
      email: this.usuarioEditando.email,
      activo: this.usuarioEditando.activo,
      rol: this.usuarioEditando.rol
    };

    this.usuariosService
      .actualizar(this.usuarioEditando.id, datos)
      .subscribe({
        next: (usuarioActualizado) => {
          const indice = this.usuarios.findIndex(
            u => u.id === usuarioActualizado.id
          );

          if (indice !== -1) {
            this.usuarios[indice] = usuarioActualizado;
          }

          this.usuarioEditando = null;
          this.mensaje = 'Usuario actualizado correctamente.';
        },
        error: (error) => {
          this.error =
            error.error?.detail ||
            'No se pudo actualizar el usuario.';
        }
      });
  }

  eliminar(usuario: Usuario): void {
    if (
      !confirm(
        `¿Seguro que deseas eliminar a ${usuario.nombre} ${usuario.apellido}?`
      )
    ) {
      return;
    }

    this.usuariosService.eliminar(usuario.id).subscribe({
      next: () => {
        this.usuarios = this.usuarios.filter(
          u => u.id !== usuario.id
        );

        this.mensaje = 'Usuario eliminado correctamente.';
      },
      error: (error) => {
        this.error =
          error.error?.detail ||
          'No se pudo eliminar el usuario.';
      }
    });
  }
}
EOF


cat > src/app/pages/usuarios/usuarios.html <<'EOF'
<div class="pagina">
  <header class="encabezado">
    <div>
      <h1>Gestión de Usuarios</h1>
      <p>Administración de usuarios de MenStyle</p>
    </div>

    <button class="btn-recargar" (click)="cargarUsuarios()">
      Recargar
    </button>
  </header>

  @if (mensaje) {
    <div class="mensaje">{{ mensaje }}</div>
  }

  @if (error) {
    <div class="error">{{ error }}</div>
  }

  @if (cargando) {
    <div class="cargando">Cargando usuarios...</div>
  }

  @if (!cargando) {
    <div class="tabla-contenedor">
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Nombre</th>
            <th>Email</th>
            <th>Rol</th>
            <th>Estado</th>
            <th>Acciones</th>
          </tr>
        </thead>

        <tbody>
          @for (usuario of usuarios; track usuario.id) {
            <tr>
              <td>{{ usuario.id }}</td>
              <td>{{ usuario.nombre }} {{ usuario.apellido }}</td>
              <td>{{ usuario.email }}</td>

              <td>
                <span
                  class="rol"
                  [class.admin]="usuario.rol === 'administrador'"
                >
                  {{ usuario.rol }}
                </span>
              </td>

              <td>
                <span
                  class="estado"
                  [class.inactivo]="!usuario.activo"
                >
                  {{ usuario.activo ? 'Activo' : 'Inactivo' }}
                </span>
              </td>

              <td class="acciones">
                <button
                  class="btn-editar"
                  (click)="editar(usuario)"
                >
                  Editar
                </button>

                <button
                  class="btn-eliminar"
                  (click)="eliminar(usuario)"
                >
                  Eliminar
                </button>
              </td>
            </tr>
          }
        </tbody>
      </table>
    </div>
  }

  @if (usuarioEditando) {
    <div class="modal-fondo">
      <div class="modal">
        <h2>Editar usuario</h2>

        <label>Nombre</label>
        <input
          [(ngModel)]="usuarioEditando.nombre"
          type="text"
        />

        <label>Apellido</label>
        <input
          [(ngModel)]="usuarioEditando.apellido"
          type="text"
        />

        <label>Email</label>
        <input
          [(ngModel)]="usuarioEditando.email"
          type="email"
        />

        <label>Rol</label>
        <select [(ngModel)]="usuarioEditando.rol">
          <option value="cliente">Cliente</option>
          <option value="administrador">Administrador</option>
        </select>

        <label class="check">
          <input
            type="checkbox"
            [(ngModel)]="usuarioEditando.activo"
          />
          Usuario activo
        </label>

        <div class="modal-acciones">
          <button
            class="btn-cancelar"
            (click)="cancelarEdicion()"
          >
            Cancelar
          </button>

          <button
            class="btn-guardar"
            (click)="guardar()"
          >
            Guardar cambios
          </button>
        </div>
      </div>
    </div>
  }
</div>
EOF


cat > src/app/pages/usuarios/usuarios.css <<'EOF'
.pagina {
  min-height: 100vh;
  padding: 35px;
  background: #f4f4f5;
}

.encabezado {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 25px;
}

h1 {
  margin: 0;
  font-size: 30px;
}

p {
  color: #666;
}

button {
  border: 0;
  border-radius: 6px;
  padding: 9px 14px;
  cursor: pointer;
  font-weight: 600;
}

.btn-recargar {
  background: #18181b;
  color: white;
}

.mensaje {
  background: #dcfce7;
  color: #166534;
  padding: 12px;
  border-radius: 6px;
  margin-bottom: 15px;
}

.error {
  background: #fee2e2;
  color: #991b1b;
  padding: 12px;
  border-radius: 6px;
  margin-bottom: 15px;
}

.cargando {
  padding: 30px;
  text-align: center;
}

.tabla-contenedor {
  background: white;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0,0,0,.08);
}

table {
  width: 100%;
  border-collapse: collapse;
}

th,
td {
  padding: 15px;
  text-align: left;
  border-bottom: 1px solid #eee;
}

th {
  background: #18181b;
  color: white;
}

.rol,
.estado {
  padding: 5px 9px;
  border-radius: 20px;
  background: #e0e7ff;
  font-size: 13px;
}

.rol.admin {
  background: #fef3c7;
}

.estado {
  background: #dcfce7;
  color: #166534;
}

.estado.inactivo {
  background: #fee2e2;
  color: #991b1b;
}

.acciones {
  display: flex;
  gap: 8px;
}

.btn-editar {
  background: #e5e7eb;
}

.btn-eliminar {
  background: #fee2e2;
  color: #991b1b;
}

.modal-fondo {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,.5);
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal {
  width: 450px;
  background: white;
  padding: 30px;
  border-radius: 12px;
}

.modal h2 {
  margin-top: 0;
}

.modal label {
  display: block;
  margin-top: 15px;
  margin-bottom: 5px;
  font-weight: 600;
}

.modal input[type="text"],
.modal input[type="email"],
.modal select {
  width: 100%;
  padding: 10px;
  border: 1px solid #ccc;
  border-radius: 6px;
}

.check {
  display: flex !important;
  align-items: center;
  gap: 8px;
}

.check input {
  width: auto;
}

.modal-acciones {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 25px;
}

.btn-cancelar {
  background: #e5e7eb;
}

.btn-guardar {
  background: #18181b;
  color: white;
}
EOF

echo "CU04 frontend creado correctamente."
