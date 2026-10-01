// ============================================================
// TRAZABILIDAD MENSTYLE
// CU: CU23 - Realizar Probador Virtual (RF13)
// FRONTEND: Vestidor virtual con MediaPipe PoseLandmarker.
// Detecta hombros/caderas/nariz, escala la prenda al torso,
// la rota según la inclinación de hombros y la sigue en vivo
// con suavizado (lerp) para evitar jitter.
// ============================================================
import {
  Component, ElementRef, OnInit, OnDestroy,
  ViewChild, inject, ChangeDetectorRef
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HeaderComponent } from '../../shared/header/header';
import { ButtonComponent } from '../../shared/ui/button/button';
import { AlertComponent } from '../../shared/ui/alert/alert';
import { SelectComponent } from '../../shared/ui/select/select';
import { ToastService } from '../../shared/ui/toast/toast.service';
import { PoseLandmarker, FilesetResolver } from '@mediapipe/tasks-vision';

interface Prenda {
  id: number;
  nombre: string;
  imagen: string;
  categoria: string;
}

@Component({
  selector: 'app-vestidor',
  standalone: true,
  imports: [CommonModule, FormsModule, HeaderComponent, ButtonComponent, AlertComponent, SelectComponent],
  templateUrl: './vestidor.html',
  styleUrl: './vestidor.css'
})
export class VestidorComponent implements OnInit, OnDestroy {
  @ViewChild('video') videoRef!: ElementRef<HTMLVideoElement>;
  @ViewChild('canvas') canvasRef!: ElementRef<HTMLCanvasElement>;

  private cdr = inject(ChangeDetectorRef);
  private toast = inject(ToastService);

  private poseLandmarker?: PoseLandmarker;
  private animationFrame?: number;
  private stream?: MediaStream;
  private prendaImagen?: HTMLImageElement;

  private posX = 0;
  private posY = 0;
  private escala = 1;
  private angulo = 0;
  private readonly LERP = 0.35;

  camaraActiva = false;
  cargando = false;
  error = '';
  poseDetectada = false;

  prendas: Prenda[] = [
    { id: 1, nombre: 'Camisa Formal Blanca',  imagen: '/imagenes/camisas/camisa-formal-blanca-png.png',  categoria: 'Camisa Formal' },
    { id: 2, nombre: 'Camisa Formal Azul',    imagen: '/imagenes/camisas/camisa-formal-azul-png.png',    categoria: 'Camisa Formal' },
    { id: 3, nombre: 'Camisa Formal Celeste', imagen: '/imagenes/camisas/camisa-formal-celeste-png.png', categoria: 'Camisa Formal' },
    { id: 4, nombre: 'Camisa Casual Blanca',  imagen: '/imagenes/camisas/camisa-casual-blanca-png.png',  categoria: 'Camisa Casual' },
    { id: 5, nombre: 'Camisa Casual Azul',    imagen: '/imagenes/camisas/camisa-casual-azul-png.png',    categoria: 'Camisa Casual' },
    { id: 6, nombre: 'Camisa Casual Gris',    imagen: '/imagenes/camisas/camisa-casual-gris-png.png',    categoria: 'Camisa Casual' }
  ];

  opcionesPrendas = this.prendas.map(p => ({
    valor: p.id.toString(),
    etiqueta: p.categoria + ' · ' + p.nombre
  }));

  prendaSeleccionada: Prenda | null = null;

  async ngOnInit() {
    await this.cargarMediaPipe();
  }

  ngOnDestroy() {
    this.detenerCamara();
    if (this.animationFrame) cancelAnimationFrame(this.animationFrame);
  }

  private async cargarMediaPipe() {
    try {
      this.cargando = true;
      const vision = await FilesetResolver.forVisionTasks(
        'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.22-rc.20250304/wasm'
      );
      this.poseLandmarker = await PoseLandmarker.createFromOptions(vision, {
        baseOptions: {
          modelAssetPath: 'https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task',
          delegate: 'GPU'
        },
        runningMode: 'VIDEO',
        numPoses: 1
      });
      this.cargando = false;
      this.cdr.detectChanges();
    } catch (e: any) {
      this.error = 'No se pudo cargar MediaPipe: ' + (e.message || e);
      this.cargando = false;
      this.cdr.detectChanges();
    }
  }

  onPrendaCambiada(valor: string) {
    const id = Number(valor);
    this.prendaSeleccionada = this.prendas.find(p => p.id === id) ?? null;
    if (this.prendaSeleccionada) {
      const img = new Image();
      img.crossOrigin = 'anonymous';
      img.onload = () => { this.prendaImagen = img; };
      img.src = this.prendaSeleccionada.imagen;
    } else {
      this.prendaImagen = undefined;
    }
  }

  async activarCamara() {
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        video: { width: 640, height: 480, facingMode: 'user' }
      });
      this.videoRef.nativeElement.srcObject = this.stream;
      await this.videoRef.nativeElement.play();
      this.camaraActiva = true;
      this.cdr.detectChanges();
      this.detectarLoop();
    } catch (e: any) {
      this.error = 'No se pudo acceder a la camara: ' + (e.message || e);
      this.cdr.detectChanges();
    }
  }

  detenerCamara() {
    if (this.stream) {
      this.stream.getTracks().forEach(t => t.stop());
      this.stream = undefined;
    }
    this.camaraActiva = false;
    if (this.animationFrame) cancelAnimationFrame(this.animationFrame);
    this.cdr.detectChanges();
  }

  descargarFoto() {
    const canvas = this.canvasRef?.nativeElement;
    if (!canvas) return;
    const link = document.createElement('a');
    link.download = 'menstyle-vestidor-' + Date.now() + '.png';
    link.href = canvas.toDataURL('image/png');
    link.click();
    this.toast.exito('Foto descargada');
  }

  private lerp(a: number, b: number, t: number): number {
    return a + (b - a) * t;
  }

  private detectarLoop = () => {
    const video = this.videoRef?.nativeElement;
    const canvas = this.canvasRef?.nativeElement;
    if (!video || !canvas || !this.poseLandmarker) return;

    if (video.readyState >= 2) {
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      const ctx = canvas.getContext('2d');
      if (ctx) {
        ctx.save();
        ctx.scale(-1, 1);
        ctx.drawImage(video, -canvas.width, 0, canvas.width, canvas.height);
        ctx.restore();

        const results = this.poseLandmarker.detectForVideo(video, performance.now());
        if (results.landmarks && results.landmarks.length > 0) {
          this.poseDetectada = true;
          const lm = results.landmarks[0];
          if (lm.length > 24) {
            const hombroIzq = lm[11];
            const hombroDer = lm[12];
            const caderaIzq = lm[23];
            const caderaDer = lm[24];

            const toCanvasX = (p: any) => (1 - p.x) * canvas.width;
            const toCanvasY = (p: any) => p.y * canvas.height;

            const hIzqX = toCanvasX(hombroIzq);
            const hIzqY = toCanvasY(hombroIzq);
            const hDerX = toCanvasX(hombroDer);
            const hDerY = toCanvasY(hombroDer);
            const cIzqX = toCanvasX(caderaIzq);
            const cIzqY = toCanvasY(caderaIzq);
            const cDerX = toCanvasX(caderaDer);
            const cDerY = toCanvasY(caderaDer);

            const centroHombrosX = (hIzqX + hDerX) / 2;
            const centroHombrosY = (hIzqY + hDerY) / 2;
            const centroCaderasX = (cIzqX + cDerX) / 2;
            const centroCaderasY = (cIzqY + cDerY) / 2;
            const centroX = (centroHombrosX + centroCaderasX) / 2;
            const centroY = (centroHombrosY + centroCaderasY) / 2;

            const anchoHombros = Math.hypot(hDerX - hIzqX, hDerY - hIzqY);
            const anchoPrenda = anchoHombros * 2.2;

            const distanciaVertical = Math.abs(centroCaderasY - centroHombrosY);
            const altoPrenda = distanciaVertical * 2.0;

            const anguloNuevo = Math.atan2(hDerY - hIzqY, hDerX - hIzqX);

            this.posX = this.lerp(this.posX, centroX, this.LERP);
            this.posY = this.lerp(this.posY, centroY, this.LERP);
            this.escala = this.lerp(this.escala, anchoPrenda, this.LERP);
            this.angulo = this.lerp(this.angulo, anguloNuevo, this.LERP);

            if (this.prendaImagen && this.prendaImagen.complete) {
              ctx.save();
              ctx.translate(this.posX, this.posY);
              ctx.rotate(this.angulo);
              ctx.shadowColor = 'rgba(0, 0, 0, 0.4)';
              ctx.shadowBlur = 15;
              ctx.shadowOffsetY = 5;
              ctx.globalAlpha = 0.95;
              ctx.drawImage(
                this.prendaImagen,
                -this.escala / 2,
                -altoPrenda / 2.5,
                this.escala,
                altoPrenda
              );
              ctx.restore();
            }
          }
        } else {
          this.poseDetectada = false;
        }
      }
    }
    this.animationFrame = requestAnimationFrame(this.detectarLoop);
  };
}