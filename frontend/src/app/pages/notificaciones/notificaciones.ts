import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { NotificacionesService, Notificacion } from '../../core/services/notificaciones.service';
import { HeaderComponent } from '../../shared/header/header';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU12 - Recibir Notificaciones
// RF: RF21 - Notificar cambios de estado
// CAPA: Angular | SERVICIO: notificaciones.service.ts
// BACKEND: GET /api/notificaciones, PUT /api/notificaciones/{id}/leer
// ============================================================
@Component({
  selector: 'app-notificaciones',
  imports: [CommonModule, HeaderComponent],
  templateUrl: './notificaciones.html',
  styleUrl: './notificaciones.css'
})
export class NotificacionesPage implements OnInit {
  private notifService = inject(NotificacionesService);
  private cdr = inject(ChangeDetectorRef);

  notificaciones: Notificacion[] = [];
  filtro: 'todas' | 'no-leidas' = 'todas';

  cargando = true;
  error = '';

  ngOnInit(): void {
    this.cargar();
  }

  cargar(): void {
    this.cargando = true;
    this.error = '';

    const peticion = this.filtro === 'todas'
      ? this.notifService.listar()
      : this.notifService.listarNoLeidas();

    peticion.subscribe({
      next: (notifs) => {
        this.notificaciones = notifs.sort(
          (a, b) => new Date(b.fecha_creacion).getTime() - new Date(a.fecha_creacion).getTime()
        );
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.cargando = false;
        if (err.status === 401) {
          this.error = 'Iniciá sesión para ver tus notificaciones.';
        } else {
          this.error = 'No se pudieron cargar las notificaciones.';
        }
        this.cdr.detectChanges();
      }
    });
  }

  cambiarFiltro(filtro: 'todas' | 'no-leidas'): void {
    this.filtro = filtro;
    this.cargar();
  }

  marcarComoLeida(notif: Notificacion): void {
    if (notif.leida) return;

    this.notifService.marcarComoLeida(notif.id).subscribe({
      next: () => {
        notif.leida = true;
        if (this.filtro === 'no-leidas') {
          this.notificaciones = this.notificaciones.filter(n => n.id !== notif.id);
        }
        this.cdr.detectChanges();
      },
      error: () => {}
    });
  }

  get contadorNoLeidas(): number {
    return this.notificaciones.filter(n => !n.leida).length;
  }

  tiempoRelativo(fechaISO: string): string {
    const iso = /Z|[+-]\d{2}:?\d{2}$/.test(fechaISO) ? fechaISO : fechaISO + 'Z';
    const fecha = new Date(iso);
    const ahora = new Date();
    const segundos = Math.floor((ahora.getTime() - fecha.getTime()) / 1000);

    if (segundos < 60) return 'ahora mismo';
    if (segundos < 3600) return `hace ${Math.floor(segundos / 60)} min`;
    if (segundos < 86400) return `hace ${Math.floor(segundos / 3600)} h`;
    if (segundos < 604800) return `hace ${Math.floor(segundos / 86400)} días`;

    const partes = new Intl.DateTimeFormat('es-BO', {
      timeZone: 'America/La_Paz',
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    }).formatToParts(fecha);
    const get = (t: string) => partes.find(p => p.type === t)?.value ?? '';
    return `${get('day')}/${get('month')}/${get('year')}`;
  }

  iconoPara(titulo: string): string {
    const t = titulo.toLowerCase();
    if (t.includes('pedido')) return '📦';
    if (t.includes('reserva')) return '📅';
    if (t.includes('pago')) return '💳';
    if (t.includes('cancel')) return '❌';
    if (t.includes('envío') || t.includes('enviado')) return '🚚';
    if (t.includes('devol')) return '↩️';
    return '🔔';
  }
}