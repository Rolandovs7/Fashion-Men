import 'package:flutter/material.dart';

/// Navigator global para redirecciones desde capas sin BuildContext (p. ej. 401/403).
class AppNavigator {
  AppNavigator._();
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}
