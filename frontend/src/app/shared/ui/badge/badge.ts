import { Component, Input } from '@angular/core';

export type BadgeTipo = 'neutral' | 'exito' | 'error' | 'aviso' | 'info' | 'acento';

const COLORES_TIPO: Record<BadgeTipo, string> = {
  neutral: 'bg-neutral-100 text-neutral-700',
  exito: 'bg-emerald-50 text-emerald-700',
  error: 'bg-red-50 text-red-700',
  aviso: 'bg-amber-50 text-amber-700',
  info: 'bg-blue-50 text-blue-700',
  acento: 'bg-amber-400 text-neutral-950'
};

// ============================================================
// SISTEMA VISUAL MENSTYLE — Badge de estado reutilizable.
// Misma paleta que `claseEstado()` de pedidos.
// ============================================================
@Component({
  selector: 'app-badge',
  standalone: true,
  templateUrl: './badge.html'
})
export class BadgeComponent {
  /** 'neutral' | 'exito' | 'error' | 'aviso' | 'info' | 'acento' */
  @Input() tipo: BadgeTipo = 'neutral';
  /** Texto rápido. Si querés contenido propio, usá ng-content. */
  @Input() etiqueta = '';

  protected get clases(): string {
    return COLORES_TIPO[this.tipo];
  }
}