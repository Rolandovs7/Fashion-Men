import { Component, Input } from '@angular/core';

// ============================================================
// SISTEMA VISUAL MENSTYLE — Estado vacío reutilizable.
// Usá ng-content para las acciones (ej. un botón "Ir al catálogo").
// ============================================================
@Component({
  selector: 'app-empty-state',
  standalone: true,
  templateUrl: './empty-state.html'
})
export class EmptyStateComponent {
  /** Emoji o SVG del contenedor. */
  @Input() icono = '📦';
  @Input() titulo = '';
  @Input() descripcion = '';
}