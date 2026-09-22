import { Component, Input, forwardRef } from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';

let siguienteId = 0;

// ============================================================
// SISTEMA VISUAL MENSTYLE — Campo de texto base.
// Implementa ControlValueAccessor: funciona con [(ngModel)]
// y con formularios reactivos.
// ============================================================
@Component({
  selector: 'app-input',
  standalone: true,
  templateUrl: './input.html',
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => InputComponent),
      multi: true
    }
  ]
})
export class InputComponent implements ControlValueAccessor {
  @Input() label = '';
  @Input() type: string = 'text';
  @Input() placeholder = '';
  @Input() autocomplete: string = 'off';
  @Input() hint = '';
  @Input() error = '';
  @Input() required = false;

  protected valor: string | null = null;
  protected deshabilitado = false;
  protected readonly uid = `input-${++siguienteId}`;

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

  protected onInput(event: Event): void {
    const valor = (event.target as HTMLInputElement).value;
    this.valor = valor;
    this.alCambiar(valor);
  }

  protected onBlur(): void {
    this.alTocar();
  }
}