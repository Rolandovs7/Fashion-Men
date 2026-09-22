import { Component, Input } from '@angular/core';

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
  @Input() razonSocial = 'MenStyle';
  @Input() subtitulo = 'Plataforma E-Commerce FashionStore.';
  @Input() academia = 'Sistemas II - U.A.G.R.M.';
  @Input() anio = new Date().getFullYear();
}