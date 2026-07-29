import 'package:flutter/material.dart';

import 'atmosfera_tipo.dart';

class AtmosferaPaleta {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color navigationBackground;
  final Color navigationIndicator;
  final Color border;
  final Color accentSoft;
  final List<Color> heroGradient;

  const AtmosferaPaleta({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.navigationBackground,
    required this.navigationIndicator,
    required this.border,
    required this.accentSoft,
    required this.heroGradient,
  });

  AtmosferaPaleta copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? navigationBackground,
    Color? navigationIndicator,
    Color? border,
    Color? accentSoft,
    List<Color>? heroGradient,
  }) {
    return AtmosferaPaleta(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      navigationBackground: navigationBackground ?? this.navigationBackground,
      navigationIndicator: navigationIndicator ?? this.navigationIndicator,
      border: border ?? this.border,
      accentSoft: accentSoft ?? this.accentSoft,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }
}

class AtmosferaPaletas {
  const AtmosferaPaletas._();

  static AtmosferaPaleta lectura(AtmosferaLectura atmosfera) {
    return switch (atmosfera) {
      AtmosferaLectura.neutra => const AtmosferaPaleta(
        primary: Color(0xFF603B73),
        secondary: Color(0xFFC75D4D),
        background: Color(0xFFF6F0E5),
        surface: Color(0xFFFFFCF5),
        navigationBackground: Color(0xFFF9F2E8),
        navigationIndicator: Color(0xFFE9DCEE),
        border: Color(0xFFD9CCBE),
        accentSoft: Color(0xFFF0E3E5),
        heroGradient: [Color(0xFFF4E9E0), Color(0xFFE9DCEE)],
      ),

      AtmosferaLectura.magica => const AtmosferaPaleta(
        primary: Color(0xFF7651A8),
        secondary: Color(0xFF9A78C5),
        background: Color(0xFFF8F4FC),
        surface: Color(0xFFFFFBFF),
        navigationBackground: Color(0xFFFAF6FD),
        navigationIndicator: Color(0xFFEADFF5),
        border: Color(0xFFE8DDF1),
        accentSoft: Color(0xFFF0E5FF),
        heroGradient: [Color(0xFFF8F3FF), Color(0xFFEDE2FA)],
      ),

      AtmosferaLectura.oscura => const AtmosferaPaleta(
        primary: Color(0xFF624B82),
        secondary: Color(0xFF85739A),
        background: Color(0xFFF1EEF4),
        surface: Color(0xFFFCFAFD),
        navigationBackground: Color(0xFFF5F1F7),
        navigationIndicator: Color(0xFFE2D8EA),
        border: Color(0xFFDED5E5),
        accentSoft: Color(0xFFEAE1F0),
        heroGradient: [Color(0xFFF1ECF6), Color(0xFFE3D8EC)],
      ),

      AtmosferaLectura.romantica => const AtmosferaPaleta(
        primary: Color(0xFFC94F7C),
        secondary: Color(0xFFE28BAA),
        background: Color(0xFFFFF5F8),
        surface: Color(0xFFFFFBFC),
        navigationBackground: Color(0xFFFFF7FA),
        navigationIndicator: Color(0xFFFFDDEA),
        border: Color(0xFFF1D9E2),
        accentSoft: Color(0xFFFFE8F0),
        heroGradient: [Color(0xFFFFF4F8), Color(0xFFFFE5EE)],
      ),

      AtmosferaLectura.misteriosa => const AtmosferaPaleta(
        primary: Color(0xFF526F9C),
        secondary: Color(0xFF7792BA),
        background: Color(0xFFF2F6FB),
        surface: Color(0xFFFBFDFF),
        navigationBackground: Color(0xFFF5F8FC),
        navigationIndicator: Color(0xFFDDE7F3),
        border: Color(0xFFDCE5EF),
        accentSoft: Color(0xFFE5EEF9),
        heroGradient: [Color(0xFFF1F6FD), Color(0xFFE2EAF4)],
      ),

      AtmosferaLectura.gotica => const AtmosferaPaleta(
        primary: Color(0xFF5D415F),
        secondary: Color(0xFF7B617D),
        background: Color(0xFFF3EFF4),
        surface: Color(0xFFFCFAFC),
        navigationBackground: Color(0xFFF7F3F7),
        navigationIndicator: Color(0xFFE6DDE7),
        border: Color(0xFFE0D7E1),
        accentSoft: Color(0xFFECE3ED),
        heroGradient: [Color(0xFFF4EFF5), Color(0xFFE6DCE8)],
      ),

      AtmosferaLectura.bosque => const AtmosferaPaleta(
        primary: Color(0xFF4F7C62),
        secondary: Color(0xFF7DA087),
        background: Color(0xFFF2F8F4),
        surface: Color(0xFFFBFEFC),
        navigationBackground: Color(0xFFF5FAF7),
        navigationIndicator: Color(0xFFDDECE2),
        border: Color(0xFFDCE8DF),
        accentSoft: Color(0xFFE5F1E8),
        heroGradient: [Color(0xFFF1F8F3), Color(0xFFE1EEE5)],
      ),

      AtmosferaLectura.marina => const AtmosferaPaleta(
        primary: Color(0xFF3E7893),
        secondary: Color(0xFF71A4B7),
        background: Color(0xFFF1F8FA),
        surface: Color(0xFFFBFEFF),
        navigationBackground: Color(0xFFF4FAFC),
        navigationIndicator: Color(0xFFDCECF1),
        border: Color(0xFFD9E8ED),
        accentSoft: Color(0xFFE2F0F4),
        heroGradient: [Color(0xFFF1F9FB), Color(0xFFDDEEF3)],
      ),

      AtmosferaLectura.epica => const AtmosferaPaleta(
        primary: Color(0xFF8A5B2E),
        secondary: Color(0xFFB78A56),
        background: Color(0xFFFBF6EF),
        surface: Color(0xFFFFFCF8),
        navigationBackground: Color(0xFFFCF8F2),
        navigationIndicator: Color(0xFFF0E0C9),
        border: Color(0xFFEADCC9),
        accentSoft: Color(0xFFF4E7D5),
        heroGradient: [Color(0xFFFCF7EF), Color(0xFFF0E0C8)],
      ),

      AtmosferaLectura.acogedora => const AtmosferaPaleta(
        primary: Color(0xFF9A6C47),
        secondary: Color(0xFFC59A72),
        background: Color(0xFFFCF7F2),
        surface: Color(0xFFFFFCF8),
        navigationBackground: Color(0xFFFCF8F4),
        navigationIndicator: Color(0xFFF2E1D3),
        border: Color(0xFFEADDD3),
        accentSoft: Color(0xFFF5E9DF),
        heroGradient: [Color(0xFFFCF8F4), Color(0xFFF3E7DD)],
      ),

      AtmosferaLectura.futurista => const AtmosferaPaleta(
        primary: Color(0xFF4D6AA8),
        secondary: Color(0xFF718BC1),
        background: Color(0xFFF2F5FB),
        surface: Color(0xFFFBFCFF),
        navigationBackground: Color(0xFFF5F7FC),
        navigationIndicator: Color(0xFFDDE4F3),
        border: Color(0xFFDCE2EF),
        accentSoft: Color(0xFFE4EAF7),
        heroGradient: [Color(0xFFF3F6FC), Color(0xFFE2E8F5)],
      ),

      AtmosferaLectura.historica => const AtmosferaPaleta(
        primary: Color(0xFF8A6547),
        secondary: Color(0xFFB28D6F),
        background: Color(0xFFFAF6F1),
        surface: Color(0xFFFFFCF8),
        navigationBackground: Color(0xFFFBF8F4),
        navigationIndicator: Color(0xFFEFE1D5),
        border: Color(0xFFE8DDD4),
        accentSoft: Color(0xFFF3E7DE),
        heroGradient: [Color(0xFFFBF7F2), Color(0xFFEFE2D7)],
      ),
    };
  }

  static AtmosferaPaleta temporada(TemporadaVisual temporada) {
    return switch (temporada) {
      TemporadaVisual.primavera => const AtmosferaPaleta(
        primary: Color(0xFF65916F),
        secondary: Color(0xFFB683A3),
        background: Color(0xFFF7FBF6),
        surface: Color(0xFFFFFCFF),
        navigationBackground: Color(0xFFF9FCF8),
        navigationIndicator: Color(0xFFE4F0E5),
        border: Color(0xFFE2EBE2),
        accentSoft: Color(0xFFF2E9F1),
        heroGradient: [Color(0xFFF5FBF5), Color(0xFFF8EEF5)],
      ),

      TemporadaVisual.verano => const AtmosferaPaleta(
        primary: Color(0xFF4E89A1),
        secondary: Color(0xFFD19A4B),
        background: Color(0xFFF6FBFC),
        surface: Color(0xFFFFFEFA),
        navigationBackground: Color(0xFFF8FCFD),
        navigationIndicator: Color(0xFFDDEEF2),
        border: Color(0xFFE0EAEC),
        accentSoft: Color(0xFFFFF0D7),
        heroGradient: [Color(0xFFF0FAFC), Color(0xFFFFF3DC)],
      ),

      TemporadaVisual.otono => const AtmosferaPaleta(
        primary: Color(0xFF9B6239),
        secondary: Color(0xFFB98255),
        background: Color(0xFFFBF6F0),
        surface: Color(0xFFFFFCF8),
        navigationBackground: Color(0xFFFCF8F3),
        navigationIndicator: Color(0xFFF0DFD0),
        border: Color(0xFFE9DCCF),
        accentSoft: Color(0xFFF4E6DA),
        heroGradient: [Color(0xFFFBF7F1), Color(0xFFF1E0D0)],
      ),

      TemporadaVisual.invierno => const AtmosferaPaleta(
        primary: Color(0xFF607D9A),
        secondary: Color(0xFF8FA7BC),
        background: Color(0xFFF3F7FA),
        surface: Color(0xFFFCFEFF),
        navigationBackground: Color(0xFFF6F9FB),
        navigationIndicator: Color(0xFFDDE8F0),
        border: Color(0xFFDDE6EC),
        accentSoft: Color(0xFFE5EEF4),
        heroGradient: [Color(0xFFF3F8FB), Color(0xFFE3ECF2)],
      ),

      TemporadaVisual.navidad => const AtmosferaPaleta(
        primary: Color(0xFF8B3E4A),
        secondary: Color(0xFFB48A43),
        background: Color(0xFFFBF7F5),
        surface: Color(0xFFFFFCFA),
        navigationBackground: Color(0xFFFCF8F6),
        navigationIndicator: Color(0xFFF1DFE1),
        border: Color(0xFFEADDDC),
        accentSoft: Color(0xFFF4E7D8),
        heroGradient: [Color(0xFFFBF5F5), Color(0xFFF4E6D7)],
      ),
    };
  }
}
