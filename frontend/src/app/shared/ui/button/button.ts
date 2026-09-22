import { Component, Input } from '@angular/core';
import { LoaderComponent } from '../loader/loader';

export type BotonVariant = 'primario' | 'secundario' | 'fantasma' | 'acento' | 'peligro';
export type BotonTamano = 'sm' | 'md' | 'lg';

const CLASES_VARIANTE: Record<BotonVariant, string> = {
  primario: 'bg-neutral-950 text-white hover:bg-neutral-800 shadow-sm',
  secundario: 'bg-white text-neutral-900 border border-neutral-300 hover:bg-neutral-50 shadow-sm',
  fantasma: 'bg-transparent text-neutral-700 hover:bg-neutral-100',
  acento: 'bg-amber-400 text-neutral-950 hover:bg-amber-300 shadow-sm',
  peligro: 'bg-red-600 text-white hover:bg-red-500 shadow-sm'
};

const CLASES_TAMANO: Record<BotonTamano, string> = {
  sm: 'px-3 py-2 text-xs gap-1.5',
  md: 'px-4 py-2.5 text-sm gap-2',
  lg: 'px-6 py-3.5 text-base gap-2.5'
};

// ============================================================
// SISTEMA VISUAL MENSTYLE — Botón base reutilizable.
// Variantes alineadas a los botones ya usados en la app
// (primario = neutral-950, acento = ámbar, peligro = rojo).
// ============================================================
@Component({
  selector: 'app-button',
  standalone: true,
  imports: [LoaderComponent],
  templateUrl: './button.html'
})
export class ButtonComponent {
  /** 'primario' | 'secundario' | 'fantasma' | 'acento' | 'peligro' */
  @Input() variant: BotonVariant = 'primario';
  /** 'sm' | 'md' | 'lg' */
  @Input() size: BotonTamano = 'md';
  @Input() type: 'button' | 'submit' | 'reset' = 'button';
  @Input() disabled = false;
  @Input() loading = false;
  /** Ocupa el 100% del ancho disponible */
  @Input() block = false;

  get clasesBoton(): string {
    return `${CLASES_VARIANTE[this.variant]} ${CLASES_TAMANO[this.size]}`;
  }

  /** El loader interno es claro sobre fondos oscuros. */
  get cargadorClaro(): boolean {
    return this.variant === 'primario' || this.variant === 'peligro';
  }
}