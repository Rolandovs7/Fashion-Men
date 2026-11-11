import { Component, Input, inject } from '@angular/core';
import { AuthService } from '../../../core/services/auth.service';

// ============================================================
// SISTEMA VISUAL MENSTYLE — Footer reutilizable.
// Replica el footer oscuro de la landing. Se conectará a las
// páginas en la Fase 2.
// ============================================================
@Component({
  selector: 'app-footer',
  standalone: true,
  templateUrl: './footer.html'
})
export class FooterComponent {
  private authService = inject(AuthService);

  /** Permite sobrescribir el nombre; por defecto usa la empresa del usuario. */
  @Input() razonSocial?: string;
  @Input() subtitulo = 'Plataforma E-Commerce FashionStore.';
  @Input() academia = 'Sistemas II - U.A.G.R.M.';
  @Input() anio = new Date().getFullYear();

  get nombreEmpresa(): string {
    return this.razonSocial?.trim() || this.authService.nombreEmpresa();
  }
}