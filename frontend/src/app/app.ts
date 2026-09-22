import { Component, inject, signal } from '@angular/core';
import { Router, RouterOutlet, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';
import { ChatWidget } from './shared/chat-widget/chat-widget';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, ChatWidget],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  private router = inject(Router);

  title = 'frontend';

  /** El chat solo se muestra en páginas internas (no login/registro/recuperación). */
  mostrarChat = signal<boolean>(false);

  // Rutas donde NO se muestra el chat
  private rutasSinChat = [
    '/login',
    '/registro',
    '/forgot-password',
    '/reset-password'
  ];

  constructor() {
    this.router.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe((event: NavigationEnd) => {
        const url = event.urlAfterRedirects;
        const mostrar = !this.rutasSinChat.some(ruta => url.startsWith(ruta));
        this.mostrarChat.set(mostrar);
      });
  }
}