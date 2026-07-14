import 'package:flutter/material.dart';

import '../models/atmosfera_club.dart';

class AtmosferaTheme {
  const AtmosferaTheme._();

  static ThemeData aplicar(ThemeData base, AtmosferaItem? atmosfera) {
    if (atmosfera == null) {
      return base;
    }

    final paleta = _paletaDesde(atmosfera.nombre);

    return base.copyWith(
      scaffoldBackgroundColor: paleta.background,

      colorScheme: base.colorScheme.copyWith(
        primary: paleta.primary,
        secondary: paleta.secondary,
        surface: paleta.surface,
      ),

      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: paleta.background,
        foregroundColor: base.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: paleta.navigationBackground,
        indicatorColor: paleta.indicator,
        elevation: 0,
        height: 76,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        color: paleta.primary,
        linearTrackColor: paleta.primary.withValues(alpha: 0.10),
      ),

      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: paleta.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  static _AtmosferaPalette _paletaDesde(String nombre) {
    final valor = nombre.trim().toLowerCase();

    if (valor.contains('oscur') ||
        valor.contains('sombra') ||
        valor.contains('gótic')) {
      return const _AtmosferaPalette(
        primary: Color(0xFF69518D),
        secondary: Color(0xFF8D78A9),
        background: Color(0xFFF3F0F7),
        surface: Color(0xFFFCFAFF),
        navigationBackground: Color(0xFFF7F3FB),
        indicator: Color(0xFFE7DDF2),
      );
    }

    if (valor.contains('románt') ||
        valor.contains('romance') ||
        valor.contains('amor')) {
      return const _AtmosferaPalette(
        primary: Color(0xFFC94F7C),
        secondary: Color(0xFFE28BAA),
        background: Color(0xFFFFF5F8),
        surface: Color(0xFFFFFBFC),
        navigationBackground: Color(0xFFFFF7FA),
        indicator: Color(0xFFFFDDEA),
      );
    }

    if (valor.contains('mág') ||
        valor.contains('magi') ||
        valor.contains('fantas') ||
        valor.contains('encant')) {
      return const _AtmosferaPalette(
        primary: Color(0xFF7651A8),
        secondary: Color(0xFF9A78C5),
        background: Color(0xFFF8F4FC),
        surface: Color(0xFFFFFBFF),
        navigationBackground: Color(0xFFFAF6FD),
        indicator: Color(0xFFEADFF5),
      );
    }

    if (valor.contains('mister') ||
        valor.contains('intriga') ||
        valor.contains('secreto')) {
      return const _AtmosferaPalette(
        primary: Color(0xFF526F9C),
        secondary: Color(0xFF7792BA),
        background: Color(0xFFF2F6FB),
        surface: Color(0xFFFBFDFF),
        navigationBackground: Color(0xFFF5F8FC),
        indicator: Color(0xFFDDE7F3),
      );
    }

    if (valor.contains('intens') ||
        valor.contains('fuego') ||
        valor.contains('eléctric')) {
      return const _AtmosferaPalette(
        primary: Color(0xFFD96F22),
        secondary: Color(0xFFE99A55),
        background: Color(0xFFFFF8EF),
        surface: Color(0xFFFFFCF8),
        navigationBackground: Color(0xFFFFF9F2),
        indicator: Color(0xFFFFE6C9),
      );
    }

    if (valor.contains('seren') ||
        valor.contains('calma') ||
        valor.contains('lumin')) {
      return const _AtmosferaPalette(
        primary: Color(0xFF488568),
        secondary: Color(0xFF71A589),
        background: Color(0xFFF2F9F5),
        surface: Color(0xFFFBFEFC),
        navigationBackground: Color(0xFFF5FAF7),
        indicator: Color(0xFFDCEFE4),
      );
    }

    return const _AtmosferaPalette(
      primary: Color(0xFF7651A8),
      secondary: Color(0xFF9A78C5),
      background: Color(0xFFF7F5FA),
      surface: Color(0xFFFFFBFF),
      navigationBackground: Color(0xFFFAF7FC),
      indicator: Color(0xFFE9E0F2),
    );
  }
}

class _AtmosferaPalette {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color navigationBackground;
  final Color indicator;

  const _AtmosferaPalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.navigationBackground,
    required this.indicator,
  });
}
