import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RolesService, Rol } from '../../core/services/roles.service';
import { TiposPagoService, TipoPago } from '../../core/services/tipos-pago.service';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { ToastService } from '../../shared/ui/toast/toast.service';
import {
  ButtonComponent,
  InputComponent,
  ModalComponent,
  AlertComponent,
  BadgeComponent,
  EmptyStateComponent,
  LoaderComponent,
} from '../../shared/ui';

type Pestana = 'roles' | 'tipos-pago';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU05 - Gestionar Roles
// RF: RF02 - Gestionar usuarios y roles
// CU: CU19 - Gestionar Tipos de Pago (Ciclo #2, incluido en esta misma
//     pantalla por compartir el patrón de "catálogo de configuración")
// RF: pendiente de confirmar según matriz oficial (RF18/RF19 relacionados)
// CAPA: Angular
// SERVICIO: core/services/roles.service.ts, core/services/tipos-pago.service.ts
// PANTALLA: pages/admin-configuracion/admin-configuracion.ts
// BACKEND: GET/POST/PUT/DELETE /api/roles, /api/tipos-pago
// Ruta protegida por adminGuard (core/guards/auth.guard.ts).
// ============================================================
@Component({
  selector: 'app-admin-configuracion',
  imports: [
    CommonModule, FormsModule, AdminShellComponent,
    ButtonComponent, InputComponent, ModalComponent,
    AlertComponent, BadgeComponent, EmptyStateComponent, LoaderComponent,
  ],
  templateUrl: './admin-configuracion.html',
  styleUrl: './admin-configuracion.css'
})
export class AdminConfiguracion implements OnInit {
  private rolesService = inject(RolesService);
  private tiposPagoService = inject(TiposPagoService);
  private toast = inject(ToastService);
  private cdr = inject(ChangeDetectorRef);

  pestana: Pestana = 'roles';

  roles: Rol[] = [];
  tiposPago: TipoPago[] = [];

  nuevoRol = { nombre: '', descripcion: '' };
  nuevoTipoPago = '';

  cargando = false;
  guardando = false;
  error = '';
  mensaje = '';

  modalAbierto = false;
  modalTitulo = '';
  modalMensaje = '';
  rolACancelar: Rol | null = null;
  tipoPagoACancelar: TipoPago | null = null;

  ngOnInit(): void {
    this.cargarTodo();
  }

  cambiarPestana(pestana: Pestana): void {
    this.pestana = pestana;
    this.error = '';
    this.mensaje = '';
  }

  cargarTodo(): void {
    this.cargando = true;

    this.rolesService.listar(false).subscribe({
      next: (roles) => {
        this.roles = roles;
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: () => { this.cargando = false; }
    });

    this.tiposPagoService.listar(false).subscribe({
      next: (tipos) => {
        this.tiposPago = tipos;
        this.cdr.detectChanges();
      }
    });
  }

  crearRol(): void {
    if (!this.nuevoRol.nombre.trim()) {
      this.error = 'El nombre del rol es obligatorio.';
      return;
    }

    this.guardando = true;
    this.error = '';

    this.rolesService.crear({
      nombre: this.nuevoRol.nombre.trim(),
      descripcion: this.nuevoRol.descripcion.trim() || null
    }).subscribe({
      next: (rol) => {
        this.roles = [...this.roles, rol];
        this.nuevoRol = { nombre: '', descripcion: '' };
        this.guardando = false;
        this.mensaje = 'Rol creado correctamente.';
        this.toast.exito('Rol creado correctamente.');
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo crear el rol.';
        this.toast.error(this.error);
        this.cdr.detectChanges();
      }
    });
  }

  abrirModalEliminarRol(rol: Rol): void {
    this.rolACancelar = rol;
    this.tipoPagoACancelar = null;
    this.modalTitulo = 'Desactivar rol';
    this.modalMensaje = `¿Estás seguro de desactivar el rol "${rol.nombre}"? Los usuarios con ese rol dejarán de poder usarlo.`;
    this.modalAbierto = true;
  }

  abrirModalEliminarTipoPago(tipo: TipoPago): void {
    this.tipoPagoACancelar = tipo;
    this.rolACancelar = null;
    this.modalTitulo = 'Desactivar tipo de pago';
    this.modalMensaje = `¿Estás seguro de desactivar el tipo de pago "${tipo.nombre}"? Dejará de estar disponible en los pedidos.`;
    this.modalAbierto = true;
  }

  cerrarModal(): void {
    this.modalAbierto = false;
    this.rolACancelar = null;
    this.tipoPagoACancelar = null;
  }

  confirmarEliminacion(): void {
    if (this.rolACancelar) {
      this.desactivarRol(this.rolACancelar);
    } else if (this.tipoPagoACancelar) {
      this.desactivarTipoPago(this.tipoPagoACancelar);
    }
    this.cerrarModal();
  }

  private desactivarRol(rol: Rol): void {
    this.rolesService.eliminar(rol.id).subscribe({
      next: (actualizado) => {
        this.roles = this.roles.map(r => r.id === actualizado.id ? actualizado : r);
        this.mensaje = 'Rol desactivado.';
        this.toast.exito('Rol desactivado.');
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.error = error.error?.detail || 'No se pudo desactivar el rol.';
        this.toast.error(this.error);
        this.cdr.detectChanges();
      }
    });
  }

  crearTipoPago(): void {
    if (!this.nuevoTipoPago.trim()) {
      this.error = 'El nombre del tipo de pago es obligatorio.';
      return;
    }

    this.guardando = true;
    this.error = '';

    this.tiposPagoService.crear(this.nuevoTipoPago.trim()).subscribe({
      next: (tipo) => {
        this.tiposPago = [...this.tiposPago, tipo];
        this.nuevoTipoPago = '';
        this.guardando = false;
        this.mensaje = 'Tipo de pago creado correctamente.';
        this.toast.exito('Tipo de pago creado correctamente.');
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.guardando = false;
        this.error = error.error?.detail || 'No se pudo crear el tipo de pago.';
        this.toast.error(this.error);
        this.cdr.detectChanges();
      }
    });
  }

  private desactivarTipoPago(tipo: TipoPago): void {
    this.tiposPagoService.eliminar(tipo.id).subscribe({
      next: (actualizado) => {
        this.tiposPago = this.tiposPago.map(t => t.id === actualizado.id ? actualizado : t);
        this.mensaje = 'Tipo de pago desactivado.';
        this.toast.exito('Tipo de pago desactivado.');
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.error = error.error?.detail || 'No se pudo desactivar el tipo de pago.';
        this.toast.error(this.error);
        this.cdr.detectChanges();
      }
    });
  }

  reactivarRol(rol: Rol): void {
    this.rolesService.actualizar(rol.id, { activo: true }).subscribe({
      next: (actualizado) => {
        this.roles = this.roles.map(r => r.id === actualizado.id ? actualizado : r);
        this.mensaje = `Rol "${rol.nombre}" reactivado.`;
        this.toast.exito(`Rol "${rol.nombre}" reactivado.`);
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.error = error.error?.detail || 'No se pudo reactivar el rol.';
        this.toast.error('No se pudo reactivar el rol.');
        this.cdr.detectChanges();
      }
    });
  }

  reactivarTipoPago(tipo: TipoPago): void {
    this.tiposPagoService.actualizar(tipo.id, { activo: true }).subscribe({
      next: (actualizado) => {
        this.tiposPago = this.tiposPago.map(t => t.id === actualizado.id ? actualizado : t);
        this.mensaje = `Tipo de pago "${tipo.nombre}" reactivado.`;
        this.toast.exito(`Tipo de pago "${tipo.nombre}" reactivado.`);
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.error = error.error?.detail || 'No se pudo reactivar el tipo de pago.';
        this.toast.error('No se pudo reactivar el tipo de pago.');
        this.cdr.detectChanges();
      }
    });
  }
}