import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'api_client.dart';

class ChatService {
  static final ChatService instance = ChatService._internal();
  factory ChatService() => instance;
  ChatService._internal();

  Future<RespuestaChat> enviarMensaje(String mensaje) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/ia/chat'),
      headers: ApiClient.jsonHeaders(),
      body: jsonEncode({'mensaje': mensaje}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo contactar al asistente virtual');
    }

    return RespuestaChat.fromJson(jsonDecode(response.body));
  }
}
