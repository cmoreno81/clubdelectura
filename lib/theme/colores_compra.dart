import 'package:flutter/material.dart';

/// Paleta de todo lo relacionado con comprar libros (botones, avisos de
/// publicidad y tarjetas verdes). Un solo sitio para cambiarla; si se añade
/// otra tienda, tendría su propia paleta aquí.
abstract final class ColoresCompra {
  /// Botones, textos e iconos principales.
  static const verde = Color(0xFF3F7A4D);

  /// Fondo de etiquetas y de iconos.
  static const verdeClaro = Color(0xFFDDEEDF);

  /// Fondo de tarjetas y de botones secundarios.
  static const fondo = Color(0xFFF1F7F2);

  /// Borde de tarjetas y de botones secundarios.
  static const borde = Color(0xFFCFE3D3);

  /// Extremos del degradado de las tarjetas verdes.
  static const degradadoClaro = Color(0xFF4C9560);
  static const degradadoOscuro = Color(0xFF2B5C3A);
}
