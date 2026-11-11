// Regresión del interceptor de sesión:
// solo un 401 real debe tratarse como sesión expirada. Los errores de
// validación/negocio del pago (400, 402, 403, 422) deben conservar su
// mensaje y NO expulsar al usuario al Login.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:mobile/services/api_client.dart';

http.Response _respuesta(int status, {String path = '/pagos'}) {
  final request = http.Request('POST', Uri.parse('https://api.test$path'));
  return http.Response('{"detail":"mensaje del backend"}', status, request: request);
}

void main() {
  test('401 de /pagos sí es error de autenticación', () {
    expect(ApiClient.esErrorAuth(_respuesta(401)), isTrue);
  });

  test('400 de validación no es error de autenticación', () {
    expect(ApiClient.esErrorAuth(_respuesta(400)), isFalse);
  });

  test('402 de pago no es error de autenticación', () {
    expect(ApiClient.esErrorAuth(_respuesta(402)), isFalse);
  });

  test('403 de permisos/negocio no es error de autenticación', () {
    expect(ApiClient.esErrorAuth(_respuesta(403)), isFalse);
  });

  test('422 de validación no es error de autenticación', () {
    expect(ApiClient.esErrorAuth(_respuesta(422)), isFalse);
  });

  test('un 401 en /auth/login es credencial inválida, no sesión vencida', () {
    expect(
      ApiClient.esErrorAuth(_respuesta(401, path: '/auth/login')),
      isFalse,
    );
  });
}
