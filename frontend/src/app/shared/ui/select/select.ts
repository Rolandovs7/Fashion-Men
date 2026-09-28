import { Component, Input, forwardRef } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

export interface OpcionSelect {
  valor: string | number;
  etiqueta: string;
}

let siguienteId = 0;

// ============================================================
// SISTEMA VISUAL MENSTYLE — Selector base reutilizable.
// Implementa ControlValueAccessor: funciona con [(ngModel)].
// Nota: el DOM entrega los valores como texto; si el backend
// espera números, convertí en el consumidor.
// ============================================================
@Component({
  selector: 'app-select',
  standalone: true,
  templateUrl: './select.html',
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => SelectComponent),
      multi: true
    }
  ]
})
export class SelectComponent implements ControlValueAccessor {
  @Input() label = '';
  /** Opciones a mostrar. Cada una con `valor` y `etiqueta`. */
  @Input() opciones: OpcionSelect[] = [];
  /** Texto de la primera opción vacía. Si está vacío, no se muestra. */
  @Input() placeholder = '';
  @Input() hint = '';
  @Input() error = '';
  @Input() required = false;

  protected valor: string | null = null;
  protected deshabilitado = false;
  protected readonly uid = `select-${++siguienteId}`;

  private alCambiar: (valor: unknown) => void = () => {};
  private alTocar: () => void = () => {};

  writeValue(valor: unknown): void {
    this.valor = valor === null || valor === undefined ? '' : String(valor);
  }

  registerOnChange(fn: (valor: unknown) => void): void {
    this.alCambiar = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.alTocar = fn;
  }

  setDisabledState(deshabilitado: boolean): void {
    this.deshabilitado = deshabilitado;
  }

  protected onChange(event: Event): void {
    const valor = (event.target as HTMLSelectElement).value;
    this.valor = valor;
    this.alCambiar(valor);
  }

  protected onBlur(): void {
    this.alTocar();
  }
}