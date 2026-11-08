class SesionExpiradaException implements Exception {
  final String mensaje;
  SesionExpiradaException([this.mensaje = 'Sesión expirada. Vuelve a iniciar sesión.']);
  @override
  String toString() => mensaje;
}
