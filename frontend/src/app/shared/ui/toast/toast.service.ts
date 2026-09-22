import { Injectable, signal } from '@angular/core';

export interface ToastDato {
  id: number;
  tipo: 'exito' | 'error' | 'aviso' | 'info';
  titulo?: string;
  mensaje: string;
  duracion: number;
}

// ============================================================
// SISTEMA VISUAL MENSTYLE — Servicio de notificaciones toast.
// Inyectable en cualquier componente/servicio:
//   toastService.exito('Pedido creado');
// El componente <app-toast> (montado en app.html) las muestra.
// ============================================================
@Injectable({ providedIn: 'root' })
export class ToastService {
  readonly toasts = signal<ToastDato[]>([]);

  private contadorId = 0;

  mostrar(tipo: ToastDato['tipo'], mensaje: string, titulo?: string, duracion = 4000): void {
    const id = ++this.contadorId;
    this.toasts.update(lista => [...lista, { id, tipo, mensaje, titulo, duracion }]);

    if (duracion > 0) {
      setTimeout(() => this.cerrar(id), duracion);
    }
  }

  cerrar(id: number): void {
    this.toasts.update(lista => lista.filter(toast => toast.id !== id));
  }

  exito(mensaje: string, titulo?: string): void {
    this.mostrar('exito', mensaje, titulo);
  }

  error(mensaje: string, titulo?: string): void {
    this.mostrar('error', mensaje, titulo, 5000);
  }

  aviso(mensaje: string, titulo?: string): void {
    this.mostrar('aviso', mensaje, titulo);
  }

  info(mensaje: string, titulo?: string): void {
    this.mostrar('info', mensaje, titulo);
  }
}