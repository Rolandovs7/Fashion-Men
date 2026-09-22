import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../core/theme.dart';

/// Pantalla de vestidor virtual: usa la cámara frontal, detecta la
/// posición del torso de la persona (hombros y caderas) y superpone
/// la imagen de la prenda escalada a esa posición, en tiempo real.
class VestidorVirtualPage extends StatefulWidget {
  final String imagenPrendaUrl;
  final String nombrePrenda;

  const VestidorVirtualPage({
    super.key,
    required this.imagenPrendaUrl,
    required this.nombrePrenda,
  });

  @override
  State<VestidorVirtualPage> createState() => _VestidorVirtualPageState();
}

class _VestidorVirtualPageState extends State<VestidorVirtualPage> {
  CameraController? _controller;
  List<CameraDescription> _camaras = [];
  final PoseDetector _detectorPose = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );

  ui.Image? _imagenPrenda;
  Pose? _poseActual;
  bool _procesandoFrame = false;
  bool _cargandoPrenda = true;
  String? _errorCamara;

  @override
  void initState() {
    super.initState();
    _cargarImagenPrenda();
    _iniciarCamara();
  }

  Future<void> _cargarImagenPrenda() async {
    try {
      final respuesta = await http.get(Uri.parse(widget.imagenPrendaUrl));
      final imagenOriginal = img.decodeImage(respuesta.bodyBytes);
      if (imagenOriginal == null) return;

      // Quitamos el fondo gris de la foto del producto (chroma key):
      // tomamos el color de la esquina superior izquierda como referencia
      // del fondo, y hacemos transparente todo pixel parecido a ese color.
      final colorFondo = imagenOriginal.getPixel(0, 0);
      final imagenSinFondo = img.Image(
        width: imagenOriginal.width,
        height: imagenOriginal.height,
        numChannels: 4,
      );

      for (int y = 0; y < imagenOriginal.height; y++) {
        for (int x = 0; x < imagenOriginal.width; x++) {
          final pixel = imagenOriginal.getPixel(x, y);
          final distancia =
              (pixel.r - colorFondo.r).abs() +
              (pixel.g - colorFondo.g).abs() +
              (pixel.b - colorFondo.b).abs();

          if (distancia < 45) {
            imagenSinFondo.setPixelRgba(x, y, 0, 0, 0, 0);
          } else {
            imagenSinFondo.setPixelRgba(
              x,
              y,
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
              255,
            );
          }
        }
      }

      final bytesPng = img.encodePng(imagenSinFondo);
      final codec = await ui.instantiateImageCodec(
        Uint8List.fromList(bytesPng),
      );
      final frame = await codec.getNextFrame();

      if (!mounted) return;
      setState(() {
        _imagenPrenda = frame.image;
        _cargandoPrenda = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoPrenda = false);
    }
  }

  Future<void> _iniciarCamara() async {
    try {
      _camaras = await availableCameras();
      final camaraFrontal = _camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _camaras.first,
      );

      final controller = CameraController(
        camaraFrontal,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() => _controller = controller);
      controller.startImageStream(_procesarFrame);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorCamara = 'No se pudo acceder a la cámara: $e');
    }
  }

  void _procesarFrame(CameraImage imagen) async {
    if (_procesandoFrame || _controller == null) return;
    _procesandoFrame = true;

    try {
      final inputImage = _convertirCameraImage(
        imagen,
        _controller!.description,
      );
      if (inputImage != null) {
        final poses = await _detectorPose.processImage(inputImage);
        if (poses.isNotEmpty && mounted) {
          setState(() => _poseActual = poses.first);
        }
      }
    } catch (_) {
      // Si un frame falla, simplemente lo saltamos y seguimos con el siguiente.
    } finally {
      _procesandoFrame = false;
    }
  }

  InputImage? _convertirCameraImage(
    CameraImage imagen,
    CameraDescription camara,
  ) {
    final bytes = imagen.planes.first.bytes;

    final rotacion =
        InputImageRotationValue.fromRawValue(camara.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    final formato =
        InputImageFormatValue.fromRawValue(imagen.format.raw) ??
        InputImageFormat.nv21;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(imagen.width.toDouble(), imagen.height.toDouble()),
        rotation: rotacion,
        format: formato,
        bytesPerRow: imagen.planes.first.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detectorPose.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Probándote: ${widget.nombrePrenda}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_errorCamara != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorCamara!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        if (_poseActual != null && _imagenPrenda != null)
          CustomPaint(
            painter: _PintorPrenda(
              pose: _poseActual!,
              imagenPrenda: _imagenPrenda!,
              tamanioImagenCamara: Size(
                _controller!.value.previewSize?.height ?? 1,
                _controller!.value.previewSize?.width ?? 1,
              ),
            ),
          ),
        if (_cargandoPrenda)
          const Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Text(
              'Cargando prenda...',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        if (_poseActual == null && !_cargandoPrenda)
          const Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Text(
              'Ubicate de frente a la cámara, con el torso completo visible.',
              style: TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

/// Dibuja la imagen de la prenda posicionada sobre el torso detectado.
class _PintorPrenda extends CustomPainter {
  final Pose pose;
  final ui.Image imagenPrenda;
  final Size tamanioImagenCamara;

  _PintorPrenda({
    required this.pose,
    required this.imagenPrenda,
    required this.tamanioImagenCamara,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hombroIzq = pose.landmarks[PoseLandmarkType.leftShoulder];
    final hombroDer = pose.landmarks[PoseLandmarkType.rightShoulder];
    final caderaIzq = pose.landmarks[PoseLandmarkType.leftHip];
    final caderaDer = pose.landmarks[PoseLandmarkType.rightHip];

    if (hombroIzq == null ||
        hombroDer == null ||
        caderaIzq == null ||
        caderaDer == null) {
      return;
    }

    final escalaX = size.width / tamanioImagenCamara.width;
    final escalaY = size.height / tamanioImagenCamara.height;

    // La cámara frontal muestra la imagen "espejada", así que invertimos X.
    Offset transformar(double x, double y) {
      return Offset(size.width - (x * escalaX), y * escalaY);
    }

    final pHombroIzq = transformar(hombroIzq.x, hombroIzq.y);
    final pHombroDer = transformar(hombroDer.x, hombroDer.y);
    final pCaderaIzq = transformar(caderaIzq.x, caderaIzq.y);
    final pCaderaDer = transformar(caderaDer.x, caderaDer.y);

    final centroHombros = Offset(
      (pHombroIzq.dx + pHombroDer.dx) / 2,
      (pHombroIzq.dy + pHombroDer.dy) / 2,
    );
    final centroCaderas = Offset(
      (pCaderaIzq.dx + pCaderaDer.dx) / 2,
      (pCaderaIzq.dy + pCaderaDer.dy) / 2,
    );

    final anchoTorso = (pHombroDer.dx - pHombroIzq.dx).abs() * 2.0;
    final altoTorso = (centroCaderas.dy - centroHombros.dy).abs() * 1.9;

    if (anchoTorso <= 0 || altoTorso <= 0) return;

    final destino = Rect.fromCenter(
      center: Offset(centroHombros.dx, centroHombros.dy + altoTorso * 0.42),
      width: anchoTorso,
      height: altoTorso,
    );

    final origen = Rect.fromLTWH(
      0,
      0,
      imagenPrenda.width.toDouble(),
      imagenPrenda.height.toDouble(),
    );

    final pintura = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(imagenPrenda, origen, destino, pintura);
  }

  @override
  bool shouldRepaint(covariant _PintorPrenda oldDelegate) => true;
}
