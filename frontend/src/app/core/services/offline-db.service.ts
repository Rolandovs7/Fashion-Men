/**
 * [Segundo Parcial] CU15 - Instalar PWA
 * [Segundo Parcial] CU16 - Consultar catálogo local
 * [Segundo Parcial] CU17 - Registrar venta offline
 * [Segundo Parcial] CU18 - Registrar reserva offline
 * [Segundo Parcial] CU19 - Consultar operaciones pendientes
 * Servicio para almacenamiento offline con IndexedDB
 */
import { Injectable } from '@angular/core';
import { openDB, DBSchema, IDBPDatabase } from 'idb';

interface MenStyleDB extends DBSchema {
  productos: {
    key: number;
    value: any;
  };
  operaciones_pendientes: {
    key: string;
    value: any;
    indexes: { 'by-fecha': string };
  };
}

@Injectable({
  providedIn: 'root'
})
export class OfflineDbService {
  private dbPromise: Promise<IDBPDatabase<MenStyleDB>>;

  constructor() {
    this.dbPromise = openDB<MenStyleDB>('MenStyleOfflineDB', 2, {
      upgrade(db, oldVersion) {
        if (!db.objectStoreNames.contains('productos')) {
          db.createObjectStore('productos', { keyPath: 'id' });
        }
        if (!db.objectStoreNames.contains('operaciones_pendientes')) {
          const store = db.createObjectStore('operaciones_pendientes', { keyPath: 'uuid' });
          store.createIndex('by-fecha', 'fecha');
        }
      }
    });
  }

  async guardarProductos(productos: any[]): Promise<void> {
    const db = await this.dbPromise;
    const tx = db.transaction('productos', 'readwrite');
    await Promise.all([
      ...productos.map((p) => tx.store.put(p)),
      tx.done
    ]);
  }

  async obtenerProductos(): Promise<any[]> {
    const db = await this.dbPromise;
    return db.getAll('productos');
  }

  async limpiarProductos(): Promise<void> {
    const db = await this.dbPromise;
    const tx = db.transaction('productos', 'readwrite');
    await tx.store.clear();
    await tx.done;
  }

  /**
   * [Segundo Parcial] CU17 - Registrar venta offline
   * [Segundo Parcial] CU18 - Registrar reserva offline
   */
  async guardarOperacionPendiente(data: {
    tipo: 'venta' | 'reserva';
    productos: any[];
    monto?: number;
    datosExtra?: any;
  }): Promise<string> {
    const db = await this.dbPromise;
    const uuid = typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`;
    const operacion = {
      uuid,
      tipo: data.tipo,
      productos: data.productos || [],
      monto: data.monto || 0,
      datosExtra: data.datosExtra || {},
      fecha: new Date().toISOString(),
      estado: 'PENDIENTE'
    };
    await db.put('operaciones_pendientes', operacion);
    return uuid;
  }

  /**
   * [Segundo Parcial] CU19 - Consultar operaciones pendientes
   */
  async obtenerOperacionesPendientes(): Promise<any[]> {
    const db = await this.dbPromise;
    const items = await db.getAllFromIndex('operaciones_pendientes', 'by-fecha');
    return items.sort((a, b) => b.fecha.localeCompare(a.fecha));
  }

  async eliminarOperacionPendiente(uuid: string): Promise<void> {
    const db = await this.dbPromise;
    await db.delete('operaciones_pendientes', uuid);
  }

  async actualizarOperacionPendiente(operacion: any): Promise<void> {
    const db = await this.dbPromise;
    await db.put('operaciones_pendientes', operacion);
  }
}
