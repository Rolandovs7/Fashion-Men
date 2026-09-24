import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { ReservasService, Reserva } from '../../core/services/reservas.service';
import { SucursalesService, Sucursal } from '../../core/services/sucursales.service';
import { HeaderComponent } from '../../shared/header/header';
import { FechaBoliviaPipe } from '../../core/pipes/fecha-bolivia.pipe';
import {
  ButtonComponent,
  ModalComponent,
  AlertComponent,
  BadgeComponent,
  BadgeTipo,
  LoaderComponent,
  EmptyStateComponent,
  FooterComponent
} from '../../shared/ui';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU-Fase | Reservas en tienda
// CAPA: Angular | SERVICIO: reservas.service.ts
// BACKEND: GET /api/reservas, PUT /api/reservas/{id}/cancelar
// ============================================================
@Component({
  selector: 'app-reservas',
  imports: [
    CommonModule,
    RouterLink,
    HeaderComponent,
    FechaBoliviaPipe,
    ButtonComponent,
    ModalComponent,
    AlertComponent,
    BadgeComponent,
    LoaderComponent,
    EmptyStateComponent,
    FooterComponent
  ],
  templateUrl: './reservas.html',
  styleUrl: './reservas.css'
})
export class ReservasPage implements OnInit {
  private reservasService = inject(ReservasService);
  private sucursalesService = inject(SucursalesService);
  private cdr = inject(ChangeDetectorRef);
  private router = inject(Router);

  reservas: Reserva[] = [];
  sucursales: Sucursal[] = [];
  cargando = true;
  error = '';
  mensaje = '';

  reservaACancelar: Reserva | null = null;

  etiquetasEstado: Record<string, string> = {
    pendiente: 'Pendiente',
    confirmada: 'Confirmada',
    cancelada: 'Cancelada',
    completada: 'Completada'
  };

  get reservasActivas(): number {
    return this.reservas.filter(r => ['pendiente', 'confirmada'].includes(r.estado)).length;
  }

  ngOnInit(): void {
    this.sucursalesService.listar(false).subscribe({ next: (s) => { this.sucursales = s; this.cdr.detectChanges(); } });
    this.cargarReservas();
  }

  cargarReservas(): void {
    this.cargando = true;
    this.error = '';

    this.reservasService.listarMisReservas().subscribe({
      next: (reservas) => {
        this.reservas = reservas;
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: (error) => {
        this.cargando = false;
        this.error = error.status === 401
          ? 'Inicia sesión para ver tus reservas.'
          : 'No se pudieron cargar tus reservas.';
        this.cdr.detectChanges();
      }
    });
  }

  nombreSucursal(id: number): string {
    return this.sucursales.find(s => s.id === id)?.nombre ?? `Sucursal #${id}`;
  }

  tipoBadge(estado: string): BadgeTipo {
    const mapa: Record<string, BadgeTipo> = {
      pendiente: 'aviso',
      confirmada: 'info',
      completada: 'exito',
      cancelada: 'error'
    };
    return mapa[estado] || 'neutral';
  }

  irAlCatalogo(): void {
    this.router.navigate(['/catalogo']);
  }

  puedeCancelar(reserva: Reserva): boolean {
    return !['cancelada', 'completada'].includes(reserva.estado);
  }

  abrirCancelacion(reserva: Reserva): void {
    this.error = '';
    this.reservaACancelar = reserva;
  }

  cerrarConfirmacionCancelacion(): void {
    this.reservaACancelar = null;
  }

  confirmarCancelacion(): void {
    if (!this.reservaACancelar) return;

    const reserva = this.reservaACancelar;
    this.reservaACancelar = null;

    this.reservasService.cancelar(reserva.id).subscribe({
      next: () => {
        this.mensaje = `Reserva #${reserva.id} cancelada.`;
        this.cargarReservas();
      },
      error: (error) => {
        this.error = error.error?.detail || 'No se pudo cancelar la reserva.';
        this.cdr.detectChanges();
      }
    });
  }
}