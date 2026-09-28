import { Component, Input } from '@angular/core';

export type LoaderTamano = 'sm' | 'md' | 'lg';

const TAMANO_CLASE: Record<LoaderTamano, string> = {
  sm: 'w-6 h-6 border-[3px]',
  md: 'w-10 h-10 border-4',
  lg: 'w-12 h-12 border-4'
};

// ============================================================
// SISTEMA VISUAL MENSTYLE — Loader (spinner) reutilizable.
// Replica el spinner ya usado en catálogo/pedidos/inicio.
// ============================================================
@Component({
  selector: 'app-loader',
  standalone: true,
  templateUrl: './loader.html'
})
export class LoaderComponent {
  /** 'sm' | 'md' | 'lg' */
  @Input() size: LoaderTamano = 'md';
  @Input() texto = '';
  /** Usá `centrado` para centrar dentro del contenedor. */
  @Input() centrado = false;
  /** `claro` para fondo oscuro (spinner blanco). */
  @Input() claro = false;

  protected get claseTamano(): string {
    return TAMANO_CLASE[this.size];
  }
}