import { Component, EventEmitter, Input, Output } from '@angular/core';

export type AlertaTipo = 'exito' | 'error' | 'aviso' | 'info';

const CLASES_TIPO: Record<AlertaTipo, string> = {
  exito: 'border-emerald-200 bg-emerald-50 text-emerald-700',
  error: 'border-red-200 bg-red-50 text-red-700',
  aviso: 'border-amber-200 bg-amber-50 text-amber-700',
  info: 'border-blue-200 bg-blue-50 text-blue-700'
};

const TRAYECTO_ICONO: Record<AlertaTipo, string> = {
  exito: 'M5 13l4 4L19 7',
  error: 'M6 18L18 6M6 6l12 12',
  aviso: 'M12 9v4m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z',
  info: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
};

// ============================================================
// SISTEMA VISUAL MENSTYLE — Alerta reutilizable (éxito/error/
// aviso/info), con los mismos colores que los estados de la app.
// ============================================================
@Component({
  selector: 'app-alert',
  standalone: true,
  templateUrl: './alert.html'
})
export class AlertComponent {
  /** 'exito' | 'error' | 'aviso' | 'info' */
  @Input() tipo: AlertaTipo = 'info';
  @Input() titulo = '';
  /** Mensaje simple. Si querés contenido propio, usá ng-content. */
  @Input() mensaje = '';
  @Input() dismissible = false;
  @Output() cerrar = new EventEmitter<void>();

  protected get clasesContenedor(): string {
    return CLASES_TIPO[this.tipo];
  }

  protected get trayectoIcono(): string {
    return TRAYECTO_ICONO[this.tipo];
  }
}