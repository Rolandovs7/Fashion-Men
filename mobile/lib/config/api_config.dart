import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Cambiá esto a la URL de Render cuando despliegues a producción.
  static const String _productionUrl = 'https://menstyle-api-n77g.onrender.com';
  static const bool useProduction =
      true; // true cuando quieras probar contra Render

  static String get baseUrl {
    if (useProduction) return _productionUrl;

    if (kIsWeb) {
      return 'http://localhost:8000'; // Chrome / Edge
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // Emulador Android
    }
    // Windows desktop, iOS simulator, etc.
    return 'http://localhost:8000';
  }
}
