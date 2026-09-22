import { Component, Input } from '@angular/core';
import { DecimalPipe } from '@angular/common';

// ============================================================
// SISTEMA VISUAL MENSTYLE — Precio reutilizable con formato
// consistente (Bs 1.234,56 por defecto).
// ============================================================
@Component({
  selector: 'app-price',
  standalone: true,
  imports: [DecimalPipe],
  templateUrl: './price.html'
})
export class PriceComponent {
  @Input() valor = 0;
  /** Simbolo/moneda a mostrar antes del número. */
  @Input() moneda = 'Bs';
  /** Formato de DecimalPipe, p. ej. '1.2-2' o '0.2-2'. */
  @Input() formato = '1.2-2';
  @Input() mostrarMoneda = true;
}