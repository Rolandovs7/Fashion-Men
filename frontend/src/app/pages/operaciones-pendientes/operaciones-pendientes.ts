/**
 * [Segundo Parcial] CU17 - Registrar venta offline
 * [Segundo Parcial] CU18 - Registrar reserva offline
 * [Segundo Parcial] CU19 - Consultar operaciones pendientes
 */
import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OfflineDbService } from '../../core/services/offline-db.service';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { LoaderComponent, EmptyStateComponent, BadgeComponent } from '../../shared/ui';

@Component({
  selector: 'app-operaciones-pendientes',
  imports: [CommonModule, AdminShellComponent, LoaderComponent, EmptyStateComponent, BadgeComponent],
  templateUrl: './operaciones-pendientes.html'
})
export class OperacionesPendientes implements OnInit {
  private offlineDb = inject(OfflineDbService);
  private cdr = inject(ChangeDetectorRef);

  operaciones: any[] = [];
  cargando = false;

  ngOnInit(): void {
    this.cargar();
  }

  async cargar(): Promise<void> {
    this.cargando = true;
    try {
      this.operaciones = await this.offlineDb.obtenerOperacionesPendientes();
    } catch (e) {
      this.operaciones = [];
    }
    this.cargando = false;
    this.cdr.detectChanges();
  }

  formatearFecha(fecha: string): string {
    try {
      return new Date(fecha).toLocaleString();
    } catch {
      return fecha;
    }
  }
}
