import { Component, EventEmitter, Input, OnInit, Output, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { Pedido } from '../../core/services/pedidos.service';
import { PagosService, Pago } from '../../core/services/pagos.service';
import { VariantesService, Variante } from '../../core/services/variantes.service';
import { ProductosService, Producto } from '../../core/services/productos.service';

interface LineaComprobante {
  variante?: Variante;
  producto?: Producto;
  cantidad: number;
  precioUnitario: number;
  subtotal: number;
}

@Component({
  selector: 'app-recibo',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './recibo.html',
  styleUrl: './recibo.css'
})
export class ReciboComponent implements OnInit {
  @Input({ required: true }) pedido!: Pedido;
  @Input() sucursalNombre: string | null = null;
  @Input() intentarCargarPagos = true;
  @Output() cerrar = new EventEmitter<void>();

  private pagosService = inject(PagosService);
  private variantesService = inject(VariantesService);
  private productosService = inject(ProductosService);
  private cdr = inject(ChangeDetectorRef);

  lineas: LineaComprobante[] = [];
  pagos: Pago[] = [];
  cargando = true;

  ngOnInit(): void {
    this.resolverLineas();

    if (this.intentarCargarPagos) {
      this.pagosService.listarPorPedido(this.pedido.id).subscribe({
        next: (pagos) => {
          this.pagos = pagos;
          this.cdr.detectChanges();
        },
        error: () => {
          // El comprobante puede verse aunque no se puedan leer los pagos
          // (por ejemplo, cuando lo abre un administrador sobre el pedido de otro usuario).
        }
      });
    }
  }

  private resolverLineas(): void {
    const detalles = this.pedido.detalles;

    if (detalles.length === 0) {
      this.cargando = false;
      return;
    }

    const solicitudesVariantes = detalles.map((d) =>
      this.variantesService.obtenerPorId(d.variante_id).pipe(catchError(() => of(null)))
    );

    forkJoin(solicitudesVariantes).subscribe((variantes) => {
      const productoIds = [...new Set(variantes.filter((v): v is Variante => !!v).map(v => v.producto_id))];

      const finalizar = (mapaProductos: Map<number, Producto>) => {
        this.lineas = detalles.map((detalle, i) => {
          const variante = variantes[i] ?? undefined;
          const producto = variante ? mapaProductos.get(variante.producto_id) : undefined;
          return {
            variante,
            producto,
            cantidad: detalle.cantidad,
            precioUnitario: detalle.precio_unitario,
            subtotal: detalle.subtotal
          };
        });
        this.cargando = false;
        this.cdr.detectChanges();
      };

      if (productoIds.length === 0) {
        finalizar(new Map());
        return;
      }

      const solicitudesProductos = productoIds.map((id) =>
        this.productosService.obtener(id).pipe(catchError(() => of(null)))
      );

      forkJoin(solicitudesProductos).subscribe((productos) => {
        const mapa = new Map<number, Producto>();
        productos.forEach(p => { if (p) mapa.set(p.id, p); });
        finalizar(mapa);
      });
    });
  }

  imprimir(): void {
    window.print();
  }

  cerrarComprobante(): void {
    this.cerrar.emit();
  }
}
