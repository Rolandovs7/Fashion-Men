import { Component, ChangeDetectorRef, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { PermisosService, Permiso } from '../../core/services/permisos.service';
import { RolesService, Rol } from '../../core/services/roles.service';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import {
  ButtonComponent,
  AlertComponent,
  SelectComponent,
  LoaderComponent,
  EmptyStateComponent,
  type OpcionSelect
} from '../../shared/ui';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU06 - Asignar Permisos (Riesgo: CRÍTICO)
// RF: RF02 - Gestionar usuarios y roles (relacionado)
// CAPA: Angular
// SERVICIO: core/services/permisos.service.ts
// PANTALLA: pages/permisos/permisos.ts
// BACKEND: GET /api/permisos, GET /api/permisos/rol/{rol},
//          POST /api/permisos/asignar, DELETE /api/permisos/quitar/{rol}/{id}
// Ruta protegida por adminGuard (core/guards/auth.guard.ts).
// ============================================================
@Component({
  selector: 'app-permisos',
  imports: [CommonModule, FormsModule, AdminShellComponent, ButtonComponent, AlertComponent, SelectComponent, LoaderComponent, EmptyStateComponent],
  templateUrl: './permisos.html',
  styleUrl: './permisos.css'
})
export class Permisos implements OnInit {

  private permisosService = inject(PermisosService);
  private rolesService = inject(RolesService);
  private cdr = inject(ChangeDetectorRef);

  permisos: Permiso[] = [];
  permisosAsignados: number[] = [];
  roles: Rol[] = [];

  rolSeleccionado = 'administrador';

  cargando = false;
  guardando = false;
  mensaje = '';
  error = '';

  ngOnInit(): void {
    this.rolesService.listar(true).subscribe({
      next: (roles) => {
        this.roles = roles;
        this.cdr.detectChanges();
      }
    });
    this.cargarPermisos();
  }

  cargarPermisos(): void {
    this.cargando = true;
    this.error = '';

    this.permisosService.listar().subscribe({
      next: (permisos) => {
        this.permisos = permisos;
        this.cargarPermisosDelRol();
      },
      error: (error) => {
        console.error(error);
        this.error = 'No se pudieron cargar los permisos.';
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  cargarPermisosDelRol(): void {
    this.permisosService.porRol(this.rolSeleccionado).subscribe({
      next: (permisos) => {
        this.permisosAsignados = permisos.map(p => p.id);
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: (error) => {
        console.error(error);
        this.error = 'No se pudieron cargar los permisos del rol.';
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  get opcionesRoles(): OpcionSelect[] {
    const fijos: OpcionSelect[] = [
      { valor: 'administrador', etiqueta: 'Administrador' },
      { valor: 'cliente', etiqueta: 'Cliente' }
    ];

    const dinamicos: OpcionSelect[] = this.roles
      .filter(r => r.nombre !== 'administrador' && r.nombre !== 'cliente')
      .map(r => ({ valor: r.nombre, etiqueta: r.nombre }));

    return [...fijos, ...dinamicos];
  }

  onRolCambiado(valor: string): void {
    this.rolSeleccionado = valor;
    this.cambiarRol();
  }

  cambiarRol(): void {
    this.mensaje = '';
    this.error = '';
    this.cargarPermisosDelRol();
  }

  tienePermiso(id: number): boolean {
    return this.permisosAsignados.includes(id);
  }

  cambiarPermiso(id: number): void {
    if (this.tienePermiso(id)) {
      this.permisosAsignados = this.permisosAsignados.filter(
        permisoId => permisoId !== id
      );
    } else {
      this.permisosAsignados = [
        ...this.permisosAsignados,
        id
      ];
    }
  }

  guardar(): void {
    this.guardando = true;
    this.mensaje = '';
    this.error = '';

    this.permisosService.porRol(this.rolSeleccionado).subscribe({
      next: (actuales) => {

        const actualesIds = actuales.map(p => p.id);

        const agregar = this.permisosAsignados.filter(
          id => !actualesIds.includes(id)
        );

        const quitar = actualesIds.filter(
          id => !this.permisosAsignados.includes(id)
        );

        let pendientes = agregar.length + quitar.length;

        if (pendientes === 0) {
          this.guardando = false;
          this.mensaje = 'Los permisos ya están actualizados.';
          this.cdr.detectChanges();
          return;
        }

        const terminado = () => {
          pendientes--;

          if (pendientes === 0) {
            this.guardando = false;
            this.mensaje = 'Permisos actualizados correctamente.';
            this.cdr.detectChanges();
          }
        };

        agregar.forEach(id => {
          this.permisosService.asignar(
            this.rolSeleccionado,
            id
          ).subscribe({
            next: terminado,
            error: (error) => {
              console.error(error);
              this.error = 'No se pudieron guardar algunos permisos.';
              terminado();
            }
          });
        });

        quitar.forEach(id => {
          this.permisosService.quitar(
            this.rolSeleccionado,
            id
          ).subscribe({
            next: terminado,
            error: (error) => {
              console.error(error);
              this.error = 'No se pudieron guardar algunos permisos.';
              terminado();
            }
          });
        });
      },
      error: (error) => {
        console.error(error);
        this.error = 'No se pudieron verificar los permisos actuales.';
        this.guardando = false;
        this.cdr.detectChanges();
      }
    });
  }
}