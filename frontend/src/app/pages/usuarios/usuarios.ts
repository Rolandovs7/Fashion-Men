import { Component, inject, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import {
  UsuariosService,
  Usuario,
  UsuarioActualizar,
  UsuarioCrear
} from '../../core/services/usuarios.service';
import { RolesService, Rol } from '../../core/services/roles.service';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU04 - Gestionar Usuarios
// RF: RF02 - Gestionar usuarios y roles
// CAPA: Angular
// SERVICIO: core/services/usuarios.service.ts
// PANTALLA: pages/usuarios/usuarios.ts
// BACKEND: GET/POST /api/usuarios, PUT/DELETE /api/usuarios/{id}
// Ruta protegida por adminGuard (core/guards/auth.guard.ts).
// El selector de rol usa CU05 (RolesService) en vez de una lista fija.
// ============================================================
@Component({
  selector: 'app-usuarios',
  imports: [CommonModule, FormsModule, AdminShellComponent],
  templateUrl: './usuarios.html'
})
export class Usuarios implements OnInit {
  private usuariosService = inject(UsuariosService);
  private rolesService = inject(RolesService);
  private cdr = inject(ChangeDetectorRef);

  usuarios: Usuario[] = [];
  roles: Rol[] = [];
  usuarioEditando: Usuario | null = null;
  error = '';
  mensaje = '';
  cargando = false;

  mostrarFormularioCrear = false;
  guardandoNuevo = false;
  nuevoUsuario: UsuarioCrear = {
    nombre: '', apellido: '', email: '', password: '', rol: 'cliente'
  };

  ngOnInit(): void {
    this.cargarUsuarios();
    this.rolesService.listar(true).subscribe({
      next: (roles) => {
        this.roles = roles;
        this.cdr.detectChanges();
      }
    });
  }

  cargarUsuarios(): void {
    this.cargando = true;
    this.error = '';

    this.usuariosService.listar().subscribe({
      next: (usuarios) => {
        this.usuarios = usuarios;
        this.cargando = false;
        this.cdr.detectChanges();
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

  abrirFormularioCrear(): void {
    this.mostrarFormularioCrear = true;
    this.nuevoUsuario = { nombre: '', apellido: '', email: '', password: '', rol: 'cliente' };
    this.error = '';
    this.mensaje = '';
  }

  cerrarFormularioCrear(): void {
    this.mostrarFormularioCrear = false;
  }

  crearUsuario(): void {
    if (!this.nuevoUsuario.nombre.trim() || !this.nuevoUsuario.apellido.trim() ||
        !this.nuevoUsuario.email.trim() || !this.nuevoUsuario.password.trim()) {
      this.error = 'Completa todos los campos obligatorios.';
      return;
    }

    this.guardandoNuevo = true;
    this.error = '';

    this.usuariosService.crear(this.nuevoUsuario).subscribe({
      next: (usuario) => {
        this.usuarios = [...this.usuarios, usuario];
        this.guardandoNuevo = false;
        this.mostrarFormularioCrear = false;
        this.mensaje = 'Usuario creado correctamente.';
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardandoNuevo = false;
        this.error = error.error?.detail || 'No se pudo crear el usuario.';
        this.cdr.detectChanges();
      }
    });
  }
}