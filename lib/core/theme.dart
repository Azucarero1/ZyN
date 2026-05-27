import 'package:flutter/material.dart';

/// Paleta de colores y constantes visuales de la app ZyN.
/// Centraliza los valores que antes estaban repetidos en cada pantalla.
class AppColors {
  AppColors._();

  static const Color granate = Color(0xFF6B2A2A);
  static const Color granateOscuro = Color(0xFF4A1A1A);
  static const Color granateProfundo = Color(0xFF2A1515);
  static const Color granateNoche = Color(0xFF1A0F0A);

  static const Color oro = Color(0xFFB89A6A);
  static const Color oroClaro = Color(0xFFE8D4A8);
  static const Color oroBrillante = Color(0xFFD4B896);

  static const Color cremaSuave = Color(0xFFF4EFEA);
  static const Color cremaPiedra = Color(0xFFE8E0D5);
}

/// Filtro sepia compartido por todas las miniaturas y vistas detalladas.
/// Definido como `const` para que Flutter lo reutilice sin recrearlo.
const ColorFilter matrizSepia = ColorFilter.matrix(<double>[
  0.9, 0.1, 0.05, 0, 0,
  0.1, 0.8, 0.05, 0, 0,
  0.1, 0.1, 0.75, 0, 0,
  0,   0,   0,    1, 0,
]);
