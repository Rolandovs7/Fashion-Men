import { Component, inject, ChangeDetectorRef, ElementRef, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { IaService, MensajeChat, ProductoSugerido } from '../../core/services/ia.service';

// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU32 - Interactuar con Asistente Virtual
// RF: RF25 - Funcionalidad basada en IA
// CAPA: Angular | COMPONENTE: shared/chat-widget
// BACKEND: POST /api/ia/chat
// ============================================================
@Component({
  selector: 'app-chat-widget',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './chat-widget.html',
  styleUrl: './chat-widget.css'
})
export class ChatWidget {
  private iaService = inject(IaService);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);

  @ViewChild('scrollContainer') scrollContainer!: ElementRef<HTMLDivElement>;

  abierto = false;
  escribiendo = false;
  mensajeActual = '';

  mensajes: MensajeChat[] = [
    {
      rol: 'bot',
      texto: '¡Hola! Soy tu asistente virtual de MenStyle. ¿En qué puedo ayudarte hoy? Puedo recomendarte prendas según ocasión, categoría o estilo.',
      hora: new Date()
    }
  ];

  toggle(): void {
    this.abierto = !this.abierto;
    if (this.abierto) {
      setTimeout(() => this.scrollAbajo(), 100);
    }
  }

  enviar(): void {
    const texto = this.mensajeActual.trim();
    if (!texto || this.escribiendo) return;

    // Agregar mensaje del usuario
    this.mensajes.push({
      rol: 'usuario',
      texto,
      hora: new Date()
    });

    this.mensajeActual = '';
    this.escribiendo = true;
    this.cdr.detectChanges();
    this.scrollAbajo();

    // Llamar al backend
    this.iaService.enviarMensaje(texto).subscribe({
      next: (resp) => {
        this.escribiendo = false;
        this.mensajes.push({
          rol: 'bot',
          texto: resp.respuesta,
          productos: resp.productos_sugeridos,
          hora: new Date()
        });
        this.cdr.detectChanges();
        this.scrollAbajo();
      },
      error: () => {
        this.escribiendo = false;
        this.mensajes.push({
          rol: 'bot',
          texto: 'Ups, tuve un problema para responderte. ¿Podés intentar de nuevo?',
          hora: new Date()
        });
        this.cdr.detectChanges();
        this.scrollAbajo();
      }
    });
  }

  onKeyDown(event: KeyboardEvent): void {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.enviar();
    }
  }

  verProducto(producto: ProductoSugerido): void {
    this.router.navigate(['/producto', producto.id]);
    this.abierto = false;
  }

  private scrollAbajo(): void {
    if (this.scrollContainer) {
      const el = this.scrollContainer.nativeElement;
      el.scrollTop = el.scrollHeight;
    }
  }

  formatearHora(fecha: Date): string {
    return fecha.toLocaleTimeString('es-BO', {
      hour: '2-digit',
      minute: '2-digit'
    });
  }
}