/**
 * [Segundo Parcial] CU15 - Instalar PWA
 * [Segundo Parcial] CU16 - Consultar catálogo local
 * Servicio para almacenamiento offline con IndexedDB
 */
import { Injectable } from '@angular/core';
import { openDB, DBSchema, IDBPDatabase } from 'idb';

interface MenStyleDB extends DBSchema {
  productos: {
    key: number;
    value: any;
  };
}

@Injectable({
  providedIn: 'root'
})
export class OfflineDbService {
  private dbPromise: Promise<IDBPDatabase<MenStyleDB>>;

  constructor() {
    this.dbPromise = openDB<MenStyleDB>('MenStyleOfflineDB', 1, {
      upgrade(db) {
        if (!db.objectStoreNames.contains('productos')) {
          db.createObjectStore('productos', { keyPath: 'id' });
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
}
