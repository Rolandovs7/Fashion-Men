import {
  Component,
  EventEmitter,
  HostListener,
  Input,
  Output,
  OnChanges,
  OnDestroy,
  SimpleChanges,
} from '@angular/core';

export type ModalAncho = 'sm' | 'md' | 'lg' | 'xl';

const ANCHO_CLASE: Record<ModalAncho, string> = {
  sm: 'max-w-md',
  md: 'max-w-lg',
  lg: 'max-w-2xl',
  xl: 'max-w-4xl'
};

// ============================================================
// SISTEMA VISUAL MENSTYLE — Modal base reutilizable.
// El estado lo controla el padre (input `abierto`) y emite
// `cerrar` cuando el usuario pide cerrar (X, backdrop, ESC).
// Alinea el estilo con los modales ya presentes en la app.
// ============================================================
@Component({
  selector: 'app-modal',
  standalone: true,
  templateUrl: './modal.html'
})
export class ModalComponent implements OnChanges, OnDestroy {
  @Input() abierto = false;
  @Input() titulo = '';
  /** 'sm' | 'md' | 'lg' | 'xl' */
  @Input() ancho: ModalAncho = 'md';
  @Input() cerrable = true;
  @Output() cerrar = new EventEmitter<void>();

  ngOnChanges(cambios: SimpleChanges): void {
    if (cambios['abierto']) {
      if (this.abierto) {
        document.body.style.overflow = 'hidden';
      } else {
        this.liberarScroll();
      }
    }
  }

  ngOnDestroy(): void {
    if (this.abierto) {
      this.liberarScroll();
    }
  }

  @HostListener('document:keydown.escape')
  onEscape(): void {
    if (this.abierto && this.cerrable) {
      this.cerrar.emit();
    }
  }

  protected solicitarCerrar(): void {
    if (this.cerrable) {
      this.cerrar.emit();
    }
  }

  protected get claseAncho(): string {
    return ANCHO_CLASE[this.ancho];
  }

  private liberarScroll(): void {
    document.body.style.overflow = '';
  }
}