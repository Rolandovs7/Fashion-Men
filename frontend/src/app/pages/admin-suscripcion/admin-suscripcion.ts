import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { SuscripcionService, Plan, SuscripcionActual } from '../../core/services/suscripcion.service';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { LoaderComponent, AlertComponent, BadgeComponent } from '../../shared/ui';

@Component({
  selector: 'app-admin-suscripcion',
  standalone: true,
  imports: [CommonModule, AdminShellComponent, LoaderComponent, AlertComponent, BadgeComponent],
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

  cambiarPlan(plan: Plan): void {
    if (this.esPlanActual(plan) || this.cambiando) return;
    this.cambiando = true;
    this.suscripcionService.cambiarPlan(plan.id).subscribe({
      next: (s) => {
        this.miSuscripcion = s;
        this.toast.exito(`Plan actualizado a "${s.plan.nombre}" correctamente.`);
        this.cambiando = false;
        this.cdr.detectChanges();
      },
      error: (e) => {
        const msg = e?.error?.detail || 'No se pudo cambiar el plan.';
        this.toast.error(msg);
        this.cambiando = false;
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
