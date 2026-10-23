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
  private mascaraCanvas?: HTMLCanvasElement;
  private prendaCanvas?: HTMLCanvasElement;

  private posX = 0;
  private posY = 0;
  private escala = 1;
  private angulo = 0;
  private readonly LERP = 0.35;

  camaraActiva = false;
  cargando = false;
  error = '';
  poseDetectada = false;
  facingMode: 'user' | 'environment' = 'user';

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
        video: { width: 640, height: 480, facingMode: this.facingMode }
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

  async cambiarCamara() {
    this.facingMode = this.facingMode === 'user' ? 'environment' : 'user';
    this.detenerCamara();
    // Pequena espera para que se libere la camara anterior
    await new Promise(r => setTimeout(r, 300));
    await this.activarCamara();
    if (!this.stream) {
      this.facingMode = this.facingMode === 'user' ? 'environment' : 'user';
      this.toast.aviso('No se pudo cambiar de cámara en este dispositivo');
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
        if (this.facingMode === 'user') {
          ctx.scale(-1, 1);
          ctx.drawImage(video, -canvas.width, 0, canvas.width, canvas.height);
        } else {
          ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        }
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

            const toCanvasX = (p: any) => this.facingMode === 'user' 
              ? (1 - p.x) * canvas.width 
              : p.x * canvas.width;
            const toCanvasY = (p: any) => p.y * canvas.height;

            const hIzqX = toCanvasX(hombroIzq);
            const hIzqY = toCanvasY(hombroIzq);
            const hDerX = toCanvasX(hombroDer);
            const hDerY = toCanvasY(hombroDer);
            const cIzqX = toCanvasX(caderaIzq);
            const cIzqY = toCanvasY(caderaIzq);
            const cDerX = toCanvasX(caderaDer);
            const cDerY = toCanvasY(caderaDer);

            const centroX = (hIzqX + hDerX + cIzqX + cDerX) / 4;
            const centroY = (hIzqY + hDerY + cIzqY + cDerY) / 4;

            const anchoHombros = Math.hypot(hDerX - hIzqX, hDerY - hIzqY);
            const anchoPrenda = anchoHombros * 2.4;

            const distanciaVertical = Math.abs((cIzqY + cDerY) / 2 - (hIzqY + hDerY) / 2);
            const altoPrenda = distanciaVertical * 2.3;

            const anguloNuevo = Math.atan2(hDerY - hIzqY, hDerX - hIzqX);

            this.posX = this.lerp(this.posX, centroX, this.LERP);
            this.posY = this.lerp(this.posY, centroY, this.LERP);
            this.escala = this.lerp(this.escala, anchoPrenda, this.LERP);
            this.angulo = this.lerp(this.angulo, anguloNuevo, this.LERP);

            // Puntos extra para cubrir cuello y brazos: nariz + punto
            // medio de hombros (cuello) y codos si están visibles.
            const nariz = lm[0];
            const codoIzq = lm[13];
            const codoDer = lm[14];

            const centroHombrosX = (hIzqX + hDerX) / 2;
            const centroHombrosY = (hIzqY + hDerY) / 2;
            const narizVisible = (nariz.visibility ?? 0) > 0.5;
            const cuelloX = narizVisible
              ? (toCanvasX(nariz) + centroHombrosX) / 2
              : centroHombrosX;
            const cuelloY = narizVisible
              ? (toCanvasY(nariz) + centroHombrosY) / 2
              : centroHombrosY;

            const dirHombroIzq = Math.sign(hIzqX - centroHombrosX) || -1;
            const dirHombroDer = Math.sign(hDerX - centroHombrosX) || 1;
            const dirCaderaIzq = Math.sign(cIzqX - centroHombrosX) || dirHombroIzq;
            const dirCaderaDer = Math.sign(cDerX - centroHombrosX) || dirHombroDer;

            const codoIzqX = toCanvasX(codoIzq);
            const codoIzqY = toCanvasY(codoIzq);
            const codoDerX = toCanvasX(codoDer);
            const codoDerY = toCanvasY(codoDer);
            const codoIzqVisible = (codoIzq.visibility ?? 0) > 0.5 && codoIzqY > centroHombrosY;
            const codoDerVisible = (codoDer.visibility ?? 0) > 0.5 && codoDerY > centroHombrosY;

            const construirPuntos = (p: number): Array<{ x: number; y: number }> => {
              const puntos: Array<{ x: number; y: number }> = [
                { x: cuelloX, y: cuelloY - p * 0.6 },
                { x: hDerX + dirHombroDer * p * 0.6, y: hDerY - p * 0.4 },
              ];
              if (codoDerVisible) {
                puntos.push({
                  x: codoDerX + Math.sign(codoDerX - centroHombrosX || 1) * p * 0.8,
                  y: codoDerY + p * 0.3
                });
              }
              puntos.push({ x: cDerX + dirCaderaDer * p, y: cDerY + p });
              puntos.push({ x: cIzqX + dirCaderaIzq * p, y: cIzqY + p });
              if (codoIzqVisible) {
                puntos.push({
                  x: codoIzqX + Math.sign(codoIzqX - centroHombrosX || -1) * p * 0.8,
                  y: codoIzqY + p * 0.3
                });
              }
              puntos.push({ x: hIzqX + dirHombroIzq * p * 0.6, y: hIzqY - p * 0.4 });
              return puntos;
            };

            const trazarPoligono = (
              c: CanvasRenderingContext2D,
              puntos: Array<{ x: number; y: number }>
            ) => {
              c.beginPath();
              c.moveTo(puntos[0].x, puntos[0].y);
              for (let i = 1; i < puntos.length; i++) {
                c.lineTo(puntos[i].x, puntos[i].y);
              }
              c.closePath();
            };

            // Clip del torso con padding 30. La mascara usa un poligono
            // apenas menor para que el feather quede dentro del clip.
            const padding = 30;
            const puntosClip = construirPuntos(padding);
            const puntosMascara = construirPuntos(padding - 6);

            // Fuera de esta area se ve el video real (brazos, cabeza, fondo).
            ctx.save();
            trazarPoligono(ctx, puntosClip);
            ctx.clip();

            // Dentro del clip: prenda OPACA con borde suave.
            if (this.prendaImagen && this.prendaImagen.complete) {
              const dx = -this.escala / 2;
              const dy = -altoPrenda / 2.2;
              const ancho = canvas.width;
              const alto = canvas.height;

              const mascara = this.mascaraCanvas ?? document.createElement('canvas');
              const prenda = this.prendaCanvas ?? document.createElement('canvas');
              this.mascaraCanvas = mascara;
              this.prendaCanvas = prenda;

              if (mascara.width !== ancho || mascara.height !== alto) {
                mascara.width = ancho;
                mascara.height = alto;
              }
              if (prenda.width !== ancho || prenda.height !== alto) {
                prenda.width = ancho;
                prenda.height = alto;
              }

              const mctx = mascara.getContext('2d');
              const pctx = prenda.getContext('2d');

              if (mctx && pctx) {
                // Mascara difusa: alpha gradual en el borde (feather real).
                mctx.clearRect(0, 0, ancho, alto);
                mctx.save();
                mctx.filter = 'blur(3px)';
                mctx.fillStyle = '#fff';
                trazarPoligono(mctx, puntosMascara);
                mctx.fill();
                mctx.restore();

                // Prenda transformada y recortada con la mascara difusa.
                pctx.clearRect(0, 0, ancho, alto);
                pctx.save();
                pctx.translate(this.posX, this.posY);
                pctx.rotate(this.angulo);
                pctx.drawImage(this.prendaImagen, dx, dy, this.escala, altoPrenda);
                pctx.restore();

                pctx.save();
                pctx.globalCompositeOperation = 'destination-in';
                pctx.drawImage(mascara, 0, 0);
                pctx.restore();

                // Dos pasadas: halo suave con blur + alpha parcial, y
                // relleno opaco al 100%.
                ctx.save();
                ctx.filter = 'blur(2px)';
                ctx.globalAlpha = 0.5;
                ctx.drawImage(prenda, 0, 0);

                ctx.filter = 'none';
                ctx.globalAlpha = 1.0;
                ctx.drawImage(prenda, 0, 0);
                ctx.restore();
              }
            }

            ctx.restore();
          }
        } else {
          this.poseDetectada = false;
        }
      }
    }
    this.animationFrame = requestAnimationFrame(this.detectarLoop);
  };
}