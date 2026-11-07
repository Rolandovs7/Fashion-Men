/**
 * [Segundo Parcial] CU02 - Suscripción (checkout simulado Stripe Billing)
 * Pantalla de pago simulada: confirma el pago y aplica el cambio de plan.
 */
import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { SuscripcionService } from '../../core/services/suscripcion.service';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { AlertComponent } from '../../shared/ui';

@Component({
  selector: 'app-admin-checkout',
  standalone: true,
  imports: [CommonModule, FormsModule, AdminShellComponent, AlertComponent],
  templateUrl: './admin-checkout.html'
})
export class AdminCheckout implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private suscripcionService = inject(SuscripcionService);
  private toast = inject(ToastService);

  planId = 0;
  planNombre = '';
  monto: number | string = 0;
  checkoutUrl = '';

  tarjeta = '';
  fecha = '';
  cvc = '';
  titular = '';
  procesando = false;
  error = '';

  ngOnInit(): void {
    const qp = this.route.snapshot.queryParamMap;
    this.planId = Number(qp.get('plan_id') || 0);
    this.planNombre = qp.get('plan_nombre') || '';
    this.monto = qp.get('monto') || 0;
    this.checkoutUrl = qp.get('checkout_url') || '';
    if (!this.planId) {
      this.error = 'No se recibió el plan a pagar. Vuelve a Mi Suscripción.';
    }
  }

  pagar(): void {
    if (!this.planId || this.procesando) return;
    if (!this.tarjeta || !this.fecha || !this.cvc) {
      this.error = 'Completa los datos de la tarjeta (simulación).';
      return;
    }
    this.error = '';
    this.procesando = true;
    this.suscripcionService.confirmarPago(this.planId, 'success').subscribe({
      next: (s) => {
        this.toast.exito(`Pago exitoso. Plan actualizado a "${s.plan?.nombre || this.planNombre}".`);
        this.procesando = false;
        this.router.navigate(['/admin/suscripcion']);
      },
      error: (e) => {
        this.error = e?.error?.detail || 'No se pudo confirmar el pago.';
        this.toast.error(this.error);
        this.procesando = false;
      }
    });
  }

  cancelar(): void {
    this.router.navigate(['/admin/suscripcion']);
  }
}
