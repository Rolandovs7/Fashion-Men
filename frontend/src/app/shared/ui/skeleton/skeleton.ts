import { Component, Input } from '@angular/core';

export type SkeletonTipo = 'texto' | 'titulo' | 'imagen' | 'bloque';

const TIPO_CLASE: Record<SkeletonTipo, string> = {
  texto: 'h-3.5 w-full',
  titulo: 'h-5 w-2/3',
  imagen: 'aspect-square w-full',
  bloque: 'h-24 w-full'
};

// ============================================================
// SISTEMA VISUAL MENSTYLE — Skeleton (placeholder de carga).
// Combínalo con `n` repeticiones o clases adicionales.
// ============================================================
@Component({
  selector: 'app-skeleton',
  standalone: true,
  templateUrl: './skeleton.html'
})
export class SkeletonComponent {
  /** 'texto' | 'titulo' | 'imagen' | 'bloque' */
  @Input() tipo: SkeletonTipo = 'texto';
  /** Clases extra (ancho/alto/redondeado personalizado). */
  @Input() clase = '';

  protected get clases(): string {
    return `${TIPO_CLASE[this.tipo]} ${this.clase}`.trim();
  }
}