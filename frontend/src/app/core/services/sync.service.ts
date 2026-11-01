/**
 * [Segundo Parcial] CU20 - Sincronización offline
 * [Segundo Parcial] RNF05 - Idempotencia
 * [Segundo Parcial] RNF06 - No eliminar operaciones en caso de fallo
 */
import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { OfflineDbService } from './offline-db.service';

@Injectable({
  providedIn: 'root'
})
export class SyncService {
  private http = inject(HttpClient);
  private offlineDb = inject(OfflineDbService);
  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/sync';

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token')}`
    });
  }

  init(): void {
    window.addEventListener('online', () => {
      this.sincronizar();
    });
  }

  async sincronizar(): Promise<any> {
    const operaciones = await this.offlineDb.obtenerOperacionesPendientes();
    if (!operaciones.length) return { resultados: [] };

    const payload = operaciones.map((op) => ({
      uuid: op.uuid,
      tipo: op.tipo,
      productos: op.productos,
      monto: op.monto,
      datosExtra: op.datosExtra,
      sucursal_id: op.datosExtra?.sucursal_id
    }));

    try {
      const res: any = await this.http.post(`${this.apiUrl}/operaciones`, payload, { headers: this.headers() }).toPromise();
      if (res && res.resultados) {
        for (const r of res.resultados) {
          if (r.estado === 'SINCRONIZADO' || r.estado === 'ya_sincronizado') {
            await this.offlineDb.eliminarOperacionPendiente(r.uuid);
          } else if (r.estado === 'CONFLICTO') {
            const op = operaciones.find((o) => o.uuid === r.uuid);
            if (op) {
              op.estado = 'CONFLICTO';
              await this.offlineDb.actualizarOperacionPendiente(op);
            }
          } else if (r.estado === 'ERROR') {
            // RNF06: no eliminar
            const op = operaciones.find((o) => o.uuid === r.uuid);
            if (op) {
              op.estado = 'ERROR';
              await this.offlineDb.actualizarOperacionPendiente(op);
            }
          }
        }
      }
      return res;
    } catch (e) {
      // RNF06: mantener pendientes
      throw e;
    }
  }
}
