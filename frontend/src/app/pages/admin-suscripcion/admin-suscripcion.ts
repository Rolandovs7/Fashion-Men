import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { SuscripcionService, Plan, SuscripcionActual } from '../../core/services/suscripcion.service';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { LoaderComponent, AlertComponent, BadgeComponent } from '../../shared/ui';

@Component({
  selector: 'app-admin-suscripcion',
  standalone: true,
  imports: [CommonModule, FormsModule, AdminShellComponent, LoaderComponent, AlertComponent, BadgeComponent],
  templateUrl: './admin-suscripcion.html'
})
export class AdminSuscripcion implements OnInit {
  private suscripcionService = inject(SuscripcionService);
  private toast = inject(ToastService);
  private cdr = inject(ChangeDetectorRef);

  cargando = true;
  cambiando = false;
  error = '';
  miSuscripcion: SuscripcionActual | null = null;
  planes: Plan[] = [];

  // Modal de pago (simulado)
  modalAbierto = false;
  planSeleccionado: Plan | null = null;
  procesandoPago = false;
  errorPago = '';
  titular = '';
  numeroTarjeta = '';
  fechaExp = '';
  cvc = '';

  ngOnInit(): void {
    this.cargar();
  }

  cargar(): void {
    this.cargando = true;
    this.error = '';
    let pendientes = 2;
    const listo = () => { pendientes--; if (pendientes <= 0) { this.cargando = false; this.cdr.detectChanges(); } };

    this.suscripcionService.obtenerMiSuscripcion().subscribe({
      next: (s) => { this.miSuscripcion = s; listo(); },
      error: (e) => { this.error = e?.error?.detail || 'No se pudo cargar la suscripción actual.'; listo(); }
    });

    this.suscripcionService.listarPlanes().subscribe({
      next: (p) => { this.planes = p; listo(); },
      error: () => { this.error = this.error || 'No se pudieron cargar los planes.'; listo(); }
    });
  }

  esPlanActual(plan: Plan): boolean {
    return !!this.miSuscripcion && this.miSuscripcion.plan.id === plan.id;
  }

  precio(plan: Plan): string {
    const n = Number(plan.precio_mensual || 0);
    return `$${n.toFixed(n % 1 === 0 ? 0 : 2)}/mes`;
  }

  /** Abre modal elegante para confirmar cambio de plan */
  cambiarPlan(plan: Plan): void {
    if (this.esPlanActual(plan) || this.procesandoPago) return;
    this.planSeleccionado = plan;
    this.errorPago = '';
    this.titular = '';
    this.numeroTarjeta = '';
    this.fechaExp = '';
    this.cvc = '';
    this.modalAbierto = true;
    this.cdr.detectChanges();
  }

  cerrarModal(): void {
    if (this.procesandoPago) return;
    this.modalAbierto = false;
    this.planSeleccionado = null;
    this.errorPago = '';
  }

  pagar(): void {
    if (!this.planSeleccionado || this.procesandoPago) return;
    if (!this.titular.trim() || !this.numeroTarjeta.trim() || !this.fechaExp.trim() || !this.cvc.trim()) {
      this.errorPago = 'Completa todos los datos de la tarjeta.';
      return;
    }
    this.errorPago = '';
    this.procesandoPago = true;
    this.suscripcionService.confirmarPago(this.planSeleccionado.id, 'success').subscribe({
      next: (s) => {
        this.toast.exito(`Plan actualizado a "${s.plan?.nombre || this.planSeleccionado?.nombre}" correctamente.`);
        this.procesandoPago = false;
        this.modalAbierto = false;
        this.planSeleccionado = null;
        this.cargar();
      },
      error: (e) => {
        this.errorPago = e?.error?.detail || 'No se pudo confirmar el pago.';
        this.toast.error(this.errorPago);
        this.procesandoPago = false;
        this.cdr.detectChanges();
      }
    });
  }

  caracteristicas(plan: Plan): string[] {
    const items: string[] = [];
    items.push(`Hasta ${plan.max_sucursales} sucursal(es)`);
    items.push(plan.permite_ia ? 'Asistente IA habilitado' : 'Sin Asistente IA');
    items.push(plan.permite_offline ? 'Sincronización offline habilitada' : 'Modo offline no incluido');
    return items;
  }
}
