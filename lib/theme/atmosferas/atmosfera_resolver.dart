import 'package:flutter/material.dart';

import 'atmosfera_paleta.dart';
import 'atmosfera_tipo.dart';

class AtmosferaVisual {
  final AtmosferaLectura lectura;
  final TemporadaVisual temporada;
  final AtmosferaPaleta paleta;

  const AtmosferaVisual({
    required this.lectura,
    required this.temporada,
    required this.paleta,
  });
}

class AtmosferaResolver {
  const AtmosferaResolver._();

  static AtmosferaVisual resolver({
    required AtmosferaLectura lectura,
    DateTime? fecha,
  }) {
    final temporada = TemporadaVisualResolver.desdeFecha(
      fecha ?? DateTime.now(),
    );

    final lecturaPaleta = AtmosferaPaletas.lectura(lectura);

    final temporadaPaleta = AtmosferaPaletas.temporada(temporada);

    final paletaCombinada = _combinar(
      lectura: lecturaPaleta,
      temporada: temporadaPaleta,
      temporadaVisual: temporada,
    );

    return AtmosferaVisual(
      lectura: lectura,
      temporada: temporada,
      paleta: paletaCombinada,
    );
  }

  static AtmosferaPaleta _combinar({
    required AtmosferaPaleta lectura,
    required AtmosferaPaleta temporada,
    required TemporadaVisual temporadaVisual,
  }) {
    final pesoTemporada = temporadaVisual == TemporadaVisual.navidad
        ? 0.32
        : 0.22;

    return AtmosferaPaleta(
      primary: _mezclar(
        lectura.primary,
        temporada.primary,
        pesoTemporada * 0.45,
      ),

      secondary: _mezclar(
        lectura.secondary,
        temporada.secondary,
        pesoTemporada * 0.65,
      ),

      background: _mezclar(
        lectura.background,
        temporada.background,
        pesoTemporada,
      ),

      surface: _mezclar(
        lectura.surface,
        temporada.surface,
        pesoTemporada * 0.35,
      ),

      navigationBackground: _mezclar(
        lectura.navigationBackground,
        temporada.navigationBackground,
        pesoTemporada,
      ),

      navigationIndicator: _mezclar(
        lectura.navigationIndicator,
        temporada.navigationIndicator,
        pesoTemporada,
      ),

      border: _mezclar(lectura.border, temporada.border, pesoTemporada * 0.75),

      accentSoft: _mezclar(
        lectura.accentSoft,
        temporada.accentSoft,
        pesoTemporada,
      ),

      heroGradient: _mezclarGradiente(
        lectura.heroGradient,
        temporada.heroGradient,
        pesoTemporada,
      ),
    );
  }

  static Color _mezclar(Color lectura, Color temporada, double pesoTemporada) {
    return Color.lerp(lectura, temporada, pesoTemporada.clamp(0.0, 1.0)) ??
        lectura;
  }

  static List<Color> _mezclarGradiente(
    List<Color> lectura,
    List<Color> temporada,
    double pesoTemporada,
  ) {
    final longitud = lectura.length < temporada.length
        ? lectura.length
        : temporada.length;

    if (longitud == 0) {
      return lectura;
    }

    return List<Color>.generate(
      longitud,
      (index) => _mezclar(lectura[index], temporada[index], pesoTemporada),
    );
  }
}
