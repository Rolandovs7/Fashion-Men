import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/chat_service.dart';
import '../core/theme.dart';
import 'producto_detalle_page.dart';

class _MensajeChat {
  final String texto;
  final bool esUsuario;
  final List<ProductoRecomendado> productos;

  _MensajeChat({
    required this.texto,
    required this.esUsuario,
    this.productos = const [],
  });
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final chatService = ChatService();
  final _controlador = TextEditingController();
  final _scrollController = ScrollController();

  final List<_MensajeChat> _mensajes = [
    _MensajeChat(
      texto:
          '¡Hola! Soy el asistente de MenStyle. ¿En qué prenda estás '
          'pensando hoy? Puedo ayudarte a encontrar algo para una ocasión, '
          'un estilo o una temporada.',
      esUsuario: false,
    ),
  ];

  bool _enviando = false;

  Future<void> _enviar() async {
    final texto = _controlador.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() {
      _mensajes.add(_MensajeChat(texto: texto, esUsuario: true));
      _enviando = true;
      _controlador.clear();
    });
    _scrollAlFinal();

    try {
      final respuesta = await chatService.enviarMensaje(texto);
      if (!mounted) return;
      setState(() {
        _mensajes.add(
          _MensajeChat(
            texto: respuesta.respuesta,
            esUsuario: false,
            productos: respuesta.productosSugeridos,
          ),
        );
        _enviando = false;
      });
      _scrollAlFinal();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajes.add(
          _MensajeChat(
            texto: 'No pude conectarme en este momento. Intenta de nuevo.',
            esUsuario: false,
          ),
        );
        _enviando = false;
      });
      _scrollAlFinal();
    }
  }

  void _scrollAlFinal() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoCatalogo,
      appBar: AppBar(title: const Text('Asistente MenStyle')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _mensajes.length + (_enviando ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _mensajes.length) {
                  return const _BurbujaEscribiendo();
                }
                return _BurbujaMensaje(mensaje: _mensajes[index]);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controlador,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu mensaje...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _enviar(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviar,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BurbujaMensaje extends StatelessWidget {
  final _MensajeChat mensaje;

  const _BurbujaMensaje({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.esUsuario;
    return Column(
      crossAxisAlignment: esUsuario
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: esUsuario ? AppTheme.negro : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(esUsuario ? 16 : 4),
              bottomRight: Radius.circular(esUsuario ? 4 : 16),
            ),
            border: esUsuario
                ? null
                : Border.all(color: const Color(0xFFEDE7DC)),
          ),
          child: Text(
            mensaje.texto,
            style: TextStyle(
              color: esUsuario ? Colors.white : AppTheme.negro,
              fontSize: 14,
            ),
          ),
        ),
        if (mensaje.productos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: mensaje.productos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final p = mensaje.productos[i];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductoDetallePage(productoId: p.id),
                      ),
                    ),
                    child: Container(
                      width: 150,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEDE7DC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bs ${p.precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            p.motivo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _BurbujaEscribiendo extends StatelessWidget {
  const _BurbujaEscribiendo();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE7DC)),
        ),
        child: const SizedBox(
          width: 24,
          height: 12,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}
