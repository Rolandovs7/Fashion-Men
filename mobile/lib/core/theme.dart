import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Tema forzado a claro (modo oscuro eliminado).
  static bool get esOscuro => false;

  static const Color negro = Color(0xFF0D0D0D);
  static const Color carbon = Color(0xFF1C1B19);
  static const Color bronce = Color(0xFFD98A2B);
  static const Color amarilloMarca = Color(0xFFFFD400);
  static const Color grisTexto = Color(0xFF6B6560);
  static const Color grisTextoOscuro = Color(0xFFB8B2A8);
  static const Color fondoClaro = Color(0xFFF7F3EC);

  static Color get fondoCatalogo => const Color(0xFFF7F3EC);
  static Color get fondoCarrito => const Color(0xFFF1EAE0);
  static Color get fondoPedidos => const Color(0xFFF4EFE6);
  static Color get fondoReservas => const Color(0xFFEFE8DC);
  static Color get fondoPerfil => Colors.white;

  static TextStyle get fuenteTitulo => GoogleFonts.cormorantGaramond();
  static TextStyle get fuenteCuerpo => GoogleFonts.jost();

  static ThemeData get temaClaro => _construirTema(Brightness.light);
  static ThemeData get light => temaClaro;

  static ThemeData _construirTema(Brightness brillo) {
    final osc = brillo == Brightness.dark;
    final colorTexto = osc ? Colors.white : negro;
    final colorFondo = osc ? const Color(0xFF141312) : Colors.white;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brillo,
      scaffoldBackgroundColor: colorFondo,
      colorScheme: ColorScheme.fromSeed(seedColor: negro, brightness: brillo),
    );

    return base.copyWith(
      textTheme: GoogleFonts.jostTextTheme(base.textTheme as TextTheme?)
          .apply(bodyColor: colorTexto, displayColor: colorTexto),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorTexto,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: fuenteTitulo.copyWith(
          color: colorTexto,
          fontWeight: FontWeight.w600,
          fontSize: 26,
          letterSpacing: 3.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: osc ? carbon : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: osc ? carbon : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: bronce, width: 1.4),
        ),
        labelStyle: fuenteCuerpo.copyWith(
          color: osc ? grisTextoOscuro : grisTexto,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: bronce,
          foregroundColor: negro,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: fuenteCuerpo.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            fontSize: 13,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorTexto,
          textStyle: fuenteCuerpo.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: osc ? carbon : Colors.white,
        indicatorColor: amarilloMarca.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return fuenteCuerpo.copyWith(
            fontSize: 10.5,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.4,
            color: sel ? amarilloMarca : (osc ? grisTextoOscuro : grisTexto),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(
            color: sel ? amarilloMarca : (osc ? grisTextoOscuro : grisTexto),
            size: sel ? 26 : 23,
          );
        }),
      ),
    );
  }
}
