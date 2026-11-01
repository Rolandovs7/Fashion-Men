/**
 * [Segundo Parcial] CU17 - Registrar venta offline
 * [Segundo Parcial] CU18 - Registrar reserva offline
 * [Segundo Parcial] CU19 - Consultar operaciones pendientes
 * [Segundo Parcial] CU20 - Sincronización offline
 * [Segundo Parcial] CU21 - Resolución de conflictos de stock
 */
import { Component, OnInit, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OfflineDbService } from '../../core/services/offline-db.service';
import { SyncService } from '../../core/services/sync.service';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { LoaderComponent, EmptyStateComponent, BadgeComponent, ButtonComponent } from '../../shared/ui';

@Component({
  selector: 'app-operaciones-pendientes',
  imports: [CommonModule, AdminShellComponent, LoaderComponent, EmptyStateComponent, BadgeComponent, ButtonComponent],
  templateUrl: './operaciones-pendientes.html'
})
export class OperacionesPendientes implements OnInit {
  private offlineDb = inject(OfflineDbService);
  private syncService = inject(SyncService);
  private cdr = inject(ChangeDetectorRef);

  operaciones: any[] = [];
  cargando = false;
  sincronizando = false;

  ngOnInit(): void {
    this.syncService.init();
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

  async sincronizarAhora(): Promise<void> {
    this.sincronizando = true;
    try {
      await this.syncService.sincronizar();
      await this.cargar();
    } catch (e) {
      // mantener pendientes
    }
    this.sincronizando = false;
    this.cdr.detectChanges();
  }

  formatearFecha(fecha: string): string {
    try {
      return new Date(fecha).toLocaleString();
    } catch {
      return fecha;
    }
  }

  getEstado(op: any): string {
    if (op.estado === 'CONFLICTO') return 'Conflicto';
    if (op.estado === 'SINCRONIZADO') return 'Sincronizada';
    if (op.estado === 'ERROR') return 'Error';
    return 'Pendiente';
  }

  getTipoBadge(op: any): any {
    return op.tipo === 'venta' ? 'acento' : 'info';
  }
}
