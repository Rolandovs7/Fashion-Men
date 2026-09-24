// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU19 - Integrar pasarela de pago
// RF: RF19 - Compras digitales con Stripe
// CAPA: Frontend Angular
// ============================================================
import {
  Component, OnInit, OnDestroy,
  inject, ChangeDetectorRef, ViewChild, ElementRef,
} from '@angular/core';
import { CommonModule } from '@angular/common';
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

declare var Stripe: any;

@Component({
  selector: 'app-checkout',
  imports: [CommonModule, RouterModule, HeaderComponent, ButtonComponent, AlertComponent, BadgeComponent, LoaderComponent, PriceComponent, FooterComponent],
  templateUrl: './checkout.html',
  styleUrl: './checkout.css',
})
export class Checkout implements OnInit, OnDestroy {
  @ViewChild('cardElement') cardElement!: ElementRef<HTMLDivElement>;

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

  private stripe: any;
  private elements: any;
  private card: any;
  private clientSecret = '';
  private paymentIntentId = '';

  tipoBadgeEstados: Record<string, 'neutral' | 'aviso' | 'info' | 'acento' | 'exito' | 'error'> = {
    pendiente: 'aviso',
    pagado: 'info',
    procesando: 'info',
    enviado: 'acento',
    entregado: 'exito',
    cancelado: 'error'
  };

  etiquetaEstados: Record<string, string> = {
    pendiente: 'Pendiente',
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
        this.iniciarStripe();
      },
      error: (err) => {
        this.errorMsg = 'No se pudo cargar el pedido';
        this.cargando = false;
      }
    });
  }

  reintentarStripe(): void {
    try { if (this.card) this.card.destroy(); } catch {}
    this.errorMsg = '';
    this.cdr.detectChanges();
    if (this.cardElement) {
      this.cardElement.nativeElement.innerHTML = '';
    }
    this.iniciarStripe();
  }

  private iniciarStripe(): void {
    this.pagosService.obtenerConfigStripe().subscribe({
      next: (config) => {
        if (!config.publishable_key) {
          this.errorMsg = 'Stripe no configurado';
          return;
        }
        // Cargar Stripe.js si no está
        if (typeof Stripe === 'undefined') {
          const script = document.createElement('script');
          script.src = 'https://js.stripe.com/v3/';
          script.onload = () => this.montarCardElement(config.publishable_key);
          document.head.appendChild(script);
        } else {
          this.montarCardElement(config.publishable_key);
        }
      },
      error: () => { this.errorMsg = 'Error obteniendo configuración de Stripe'; }
    });
  }

  private montarCardElement(publishableKey: string): void {
    this.stripe = Stripe(publishableKey);
    this.elements = this.stripe.elements();

    // Crear PaymentIntent
    this.pagosService.crearStripeIntent(this.pedidoId).subscribe({
      next: (res) => {
        this.clientSecret = res.client_secret;
        this.paymentIntentId = res.payment_intent_id;
        this.cdr.detectChanges();

        // Esperar a que el DOM tenga el cardElement
        setTimeout(() => {
          if (!this.cardElement) return;
          const style = {
            base: {
              fontSize: '16px',
              color: '#1f2937',
              '::placeholder': { color: '#9ca3af' },
            },
          };
          this.card = this.elements.create('card', { style });
          this.card.mount(this.cardElement.nativeElement);
        }, 100);
      },
      error: (err) => {
        this.errorMsg = err.error?.detail || 'Error creando intent de pago';
      }
    });
  }

  pagar(): void {
    if (!this.stripe || !this.card || !this.clientSecret) return;
    this.procesando = true;
    this.errorMsg = '';

    this.stripe.confirmCardPayment(this.clientSecret, {
      payment_method: { card: this.card }
    }).then((result: any) => {
      if (result.error) {
        this.errorMsg = result.error.message || 'Error procesando pago';
        this.procesando = false;
        this.cdr.detectChanges();
      } else if (result.paymentIntent.status === 'succeeded') {
        // Confirmar en backend
        this.pagosService.confirmarStripePago(this.paymentIntentId).subscribe({
          next: () => {
            this.exitoMsg = '¡Pago exitoso!';
            this.procesando = false;
            this.cdr.detectChanges();
            setTimeout(() => this.router.navigate(['/pedidos']), 2000);
          },
          error: () => {
            this.errorMsg = 'Pago procesado pero error al confirmar en backend';
            this.procesando = false;
            this.cdr.detectChanges();
          }
        });
      }
    });
  }

  ngOnDestroy(): void {
    if (this.card) {
      try { this.card.destroy(); } catch {}
    }
  }
}
