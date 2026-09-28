import { Component, inject } from '@angular/core';
import { ToastService } from './toast.service';

export type ToastTipo = 'exito' | 'error' | 'aviso' | 'info';

const CLASES_TIPO: Record<ToastTipo, string> = {
  exito: 'border-emerald-200',
  error: 'border-red-200',
  aviso: 'border-amber-200',
  info: 'border-blue-200'
};

const COLOR_ICONO: Record<ToastTipo, string> = {
  exito: 'text-emerald-500',
  error: 'text-red-500',
  aviso: 'text-amber-500',
  info: 'text-blue-500'
};

const TRAYECTO_ICONO: Record<ToastTipo, string> = {
  exito: 'M5 13l4 4L19 7',
  error: 'M6 18L18 6M6 6l12 12',
  aviso: 'M12 9v4m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z',
  info: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
};

// ============================================================
// SISTEMA VISUAL MENSTYLE — Contenedor global de toasts.
// Se monta una sola vez (src/app/app.html). Las notificaciones
// llegan desde ToastService.
// ============================================================
@Component({
  selector: 'app-toast',
  standalone: true,
  templateUrl: './toast.html'
})
export class ToastComponent {
  private toastService = inject(ToastService);

  protected toasts = this.toastService.toasts;

  protected claseTipo(tipo: ToastTipo): string {
    return CLASES_TIPO[tipo];
  }

  protected claseIcono(tipo: ToastTipo): string {
    return COLOR_ICONO[tipo];
  }

  protected trayectoIcono(tipo: ToastTipo): string {
    return TRAYECTO_ICONO[tipo];
  }

  protected cerrar(id: number): void {
    this.toastService.cerrar(id);
  }
}