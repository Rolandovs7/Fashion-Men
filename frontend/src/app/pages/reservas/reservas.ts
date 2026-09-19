import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ReservasService, Reserva } from '../../core/services/reservas.service';
import { SucursalesService, Sucursal } from '../../core/services/sucursales.service';
import { HeaderComponent } from '../../shared/header/header';
import { FechaBoliviaPipe } from '../../core/pipes/fecha-bolivia.pipe';

@Component({
  selector: 'app-reservas',
  imports: [CommonModule, RouterLink, HeaderComponent, FechaBoliviaPipe],
  templateUrl: './reservas.html',
  styleUrl: './reservas.css'
})
export class ReservasPage implements OnInit {
  private reservasService = inject(ReservasService);
  private sucursalesService = inject(SucursalesService);
  private cdr = inject(ChangeDetectorRef);

  reservas: Reserva[] = [];
  sucursales: Sucursal[] = [];
  cargando = true;
  error = '';
  mensaje = '';

  etiquetasEstado: Record<string, string> = {
    pendiente: 'Pendiente',
    confirmada: 'Confirmada',
    cancelada: 'Cancelada',
    completada: 'Completada'
  };

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

  cancelarReserva(reserva: Reserva): void {
    if (!confirm(`¿Cancelar la reserva #${reserva.id}?`)) return;

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

  puedeCancelar(reserva: Reserva): boolean {
    return !['cancelada', 'completada'].includes(reserva.estado);
  }

  claseEstado(estado: string): string {
    const clases: Record<string, string> = {
      pendiente: 'bg-amber-50 text-amber-700',
      confirmada: 'bg-blue-50 text-blue-700',
      completada: 'bg-emerald-50 text-emerald-700',
      cancelada: 'bg-red-50 text-red-700'
    };
    return clases[estado] || 'bg-neutral-100 text-neutral-700';
  }
}
