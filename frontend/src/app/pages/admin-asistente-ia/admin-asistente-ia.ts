/**
 * [Segundo Parcial] CU23 - Reportes Generativos (Text-to-SQL con Gemini)
 * [Segundo Parcial] RN-IA-01 - Seguridad SQL
 */
import { Component, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { AdminShellComponent } from '../../shared/admin-shell/admin-shell';
import { ButtonComponent } from '../../shared/ui';

@Component({
  selector: 'app-admin-asistente-ia',
  imports: [CommonModule, FormsModule, AdminShellComponent, ButtonComponent],
  templateUrl: './admin-asistente-ia.html',
})
export class AdminAsistenteIa {
  private http = inject(HttpClient);
  private cdr = inject(ChangeDetectorRef);

  private apiUrl = 'https://menstyle-api-n77g.onrender.com/api/ia';

  pregunta = '';
  consultando = false;
  resultado: any = null;
  error = '';
  grabando = false;
  recognition: any = null;

  constructor() {
    if (typeof window !== 'undefined') {
      const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
      if (SpeechRecognition) {
        this.recognition = new SpeechRecognition();
        this.recognition.lang = 'es-ES';
        this.recognition.continuous = false;
        this.recognition.interimResults = false;
        this.recognition.onresult = (event: any) => {
          const transcript = event.results[0][0].transcript;
          this.pregunta = transcript;
          this.grabando = false;
          this.cdr.detectChanges();
        };
        this.recognition.onerror = () => {
          this.grabando = false;
          this.cdr.detectChanges();
        };
        this.recognition.onend = () => {
          this.grabando = false;
          this.cdr.detectChanges();
        };
      }
    }
  }

  private headers(): HttpHeaders {
    return new HttpHeaders({
      Authorization: `Bearer ${localStorage.getItem('access_token') || ''}`,
    });
  }

  escuchar(): void {
    if (!this.recognition) {
      this.error = 'Reconocimiento de voz no soportado en este navegador';
      return;
    }
    this.error = '';
    this.grabando = true;
    try {
      this.recognition.start();
    } catch {
      this.grabando = false;
    }
  }

  preguntar(): void {
    if (!this.pregunta.trim()) return;
    this.consultando = true;
    this.error = '';
    this.resultado = null;
    this.http
      .post<any>(`${this.apiUrl}/consultar`, { pregunta: this.pregunta }, { headers: this.headers() })
      .subscribe({
        next: (res) => {
          this.resultado = res;
          this.consultando = false;
          if (res?.mensaje && !res?.resultados?.length && res?.sql === '') {
            this.error = res.mensaje;
          }
          this.cdr.detectChanges();
        },
        error: (err) => {
          this.error = err?.error?.detail || err?.message || 'Error al consultar IA';
          this.consultando = false;
          this.cdr.detectChanges();
        },
      });
  }
}
