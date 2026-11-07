// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU19 - Integrar pasarela de pago / [Segundo Parcial] CU02 - Checkout tienda (simulado)
// RF: RF19 - Compras digitales
// CAPA: Frontend Angular
// ============================================================
import {
  Component, OnInit,
  inject, ChangeDetectorRef,
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { PagosService } from '../../core/services/pagos.service';
import { PedidosService, Pedido } from '../../core/services/pedidos.service';
import { HeaderComponent } from '../../shared/header/header';
import {
  ButtonComponent,
  AlertComponent,
  BadgeComponent,
  LoaderComponent,
  PriceComponent,
  FooterComponent
} from '../../shared/ui';

type MetodoPago = 'tarjeta' | 'qr' | 'efectivo';

@Component({
  selector: 'app-checkout',
  imports: [CommonModule, FormsModule, RouterModule, HeaderComponent, ButtonComponent, AlertComponent, BadgeComponent, LoaderComponent, PriceComponent, FooterComponent],
  templateUrl: './checkout.html',
  styleUrl: './checkout.css',
})
export class Checkout implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private pagosService = inject(PagosService);
  private pedidosService = inject(PedidosService);
  private cdr = inject(ChangeDetectorRef);

  pedidoId!: number;
  pedido: Pedido | null = null;
  cargando = true;
  procesando = false;
  errorMsg = '';
  exitoMsg = '';

  metodoPago: MetodoPago = 'tarjeta';

  // Tarjeta simulada (3 campos)
  numeroTarjeta = '';
  fechaExp = '';
  cvc = '';
  intentoPagar = false;

  tipoBadgeEstados: Record<string, 'neutral' | 'aviso' | 'info' | 'acento' | 'exito' | 'error'> = {
    pendiente: 'aviso',
    pendiente_pago: 'aviso',
    pagado: 'info',
    procesando: 'info',
    enviado: 'acento',
    entregado: 'exito',
    cancelado: 'error'
  };

  etiquetaEstados: Record<string, string> = {
    pendiente: 'Pendiente',
    pendiente_pago: 'Pendiente de Pago',
    pagado: 'Pagado',
    procesando: 'Procesando',
    enviado: 'Enviado',
    entregado: 'Entregado',
    cancelado: 'Cancelado'
  };

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('pedidoId');
    if (!id) {
      this.errorMsg = 'Pedido no especificado';
      this.cargando = false;
      return;
    }
    this.pedidoId = Number(id);
    this.cargarPedido();
  }

  private cargarPedido(): void {
    this.pedidosService.obtener(this.pedidoId).subscribe({
      next: (p) => {
        this.pedido = p;
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.errorMsg = 'No se pudo cargar el pedido';
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  cambiarMetodoPago(metodo: MetodoPago): void {
    this.metodoPago = metodo;
    this.errorMsg = '';
    this.intentoPagar = false;
  }

  // --- Formateo / validación visual tarjeta ---
  onNumeroInput(): void {
    const digits = this.numeroTarjeta.replace(/\D/g, '').slice(0, 16);
    this.numeroTarjeta = digits.replace(/(.{4})/g, '$1 ').trim();
  }

  onFechaInput(): void {
    const digits = this.fechaExp.replace(/\D/g, '').slice(0, 4);
    if (digits.length <= 2) this.fechaExp = digits;
    else this.fechaExp = digits.slice(0, 2) + '/' + digits.slice(2);
  }

  onCvcInput(): void {
    this.cvc = this.cvc.replace(/\D/g, '').slice(0, 4);
  }

  get numeroValido(): boolean {
    return this.numeroTarjeta.replace(/\s/g, '').length === 16;
  }

  get fechaValida(): boolean {
    if (!/^\d{2}\/\d{2}$/.test(this.fechaExp)) return false;
    const [mm, aa] = this.fechaExp.split('/').map(Number);
    if (mm < 1 || mm > 12) return false;
    // validación simple: no exigir futuro estricto en simulación, solo formato/mes válido
    return aa >= 0 && aa <= 99;
  }

  get cvcValido(): boolean {
    return this.cvc.length >= 3 && this.cvc.length <= 4;
  }

  get tarjetaValida(): boolean {
    return this.numeroValido && this.fechaValida && this.cvcValido;
  }

  claseInput(valido: boolean, valor: string): string {
    const base = 'w-full rounded-xl border px-3 py-2.5 text-sm outline-none transition-all bg-white';
    if (!this.intentoPagar && !valor) return base + ' border-ms-stone-200 focus:border-ms-amber focus:ring-2 focus:ring-ms-amber/20';
    if (valido) return base + ' border-emerald-400 focus:ring-2 focus:ring-emerald-200';
    return base + ' border-red-400 focus:ring-2 focus:ring-red-200';
  }

  // [Segundo Parcial] CU02 - Envío de pago simulado al backend
  confirmarPago(): void {
    if (!this.pedido || this.procesando) return;
    this.errorMsg = '';

    if (this.metodoPago === 'tarjeta') {
      this.intentoPagar = true;
      if (!this.tarjetaValida) {
        this.errorMsg = 'Revisa los datos de la tarjeta.';
        this.cdr.detectChanges();
        return;
      }
    }

    this.procesando = true;
    const referencia = this.metodoPago === 'tarjeta'
      ? `SIM-TARJETA-${Date.now()}`
      : this.metodoPago === 'qr' ? `QR-${Date.now()}` : `EFECTIVO-${Date.now()}`;

    this.pagosService.registrarPago({
      pedido_id: this.pedido.id,
      metodo: this.metodoPago,
      monto: this.pedido.total,
      referencia,
    }).subscribe({
      next: (pago) => {
        this.procesando = false;
        if (this.metodoPago === 'tarjeta') {
          this.exitoMsg = '¡Pago exitoso!';
        } else if (this.metodoPago === 'qr') {
          this.exitoMsg = 'Pedido registrado. Tu pago por QR quedó como Pendiente de Pago.';
        } else {
          this.exitoMsg = 'Pedido registrado. Tu pago en efectivo quedó como Pendiente de Pago (reservado por 24 horas).';
        }
        if (pago?.estado === 'aprobado' || this.pedido) {
          if (this.pedido) this.pedido = { ...this.pedido, estado: pago?.estado === 'aprobado' ? 'pagado' : 'pendiente_pago' };
        }
        this.cdr.detectChanges();
        setTimeout(() => this.router.navigate(['/pedidos']), 2500);
      },
      error: (err) => {
        this.procesando = false;
        this.errorMsg = err?.error?.detail || 'Error al procesar el pago';
        this.cdr.detectChanges();
      }
    });
  }
}
