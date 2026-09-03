import 'package:flutter/material.dart';

import 'atmosfera_resolver.dart';

class AtmosferaAppTheme {
  const AtmosferaAppTheme._();

  static ThemeData aplicar({
    required ThemeData base,
    required AtmosferaVisual atmosfera,
  }) {
    final paleta = atmosfera.paleta;

    const textoPrincipal = Color(0xFF222222);
    const textoSecundario = Color(0xFF767176);

    final colorScheme = base.colorScheme.copyWith(
      primary: paleta.primary,
      secondary: paleta.secondary,
      surface: paleta.surface,
      primaryContainer: paleta.accentSoft,
      secondaryContainer: paleta.navigationIndicator,
      outline: paleta.border,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textoPrincipal,
    );

    final textTheme = base.textTheme.apply(
      bodyColor: textoPrincipal,
      displayColor: textoPrincipal,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,

      scaffoldBackgroundColor: Colors.transparent,

      iconTheme: IconThemeData(color: paleta.primary),

      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: paleta.background.withValues(alpha: 0.94),
        foregroundColor: textoPrincipal,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textoPrincipal),
        actionsIconTheme: IconThemeData(color: paleta.primary),
      ),

      cardTheme: base.cardTheme.copyWith(
        color: paleta.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: paleta.primary.withValues(alpha: 0.10),
      ),

      dividerTheme: DividerThemeData(
        color: paleta.border,
        thickness: 1,
        space: 1,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        shadowColor: const Color(0xFF4E3A5E),
        backgroundColor: paleta.navigationBackground,
        indicatorColor: paleta.navigationIndicator,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: paleta.primary, size: 25);
          }
          return const IconThemeData(color: Color(0xFF8A7A70), size: 23);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: paleta.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            );
          }
          return const TextStyle(
            color: Color(0xFF8A7A70),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: paleta.accentSoft.withValues(alpha: 0.60),
        focusColor: paleta.primary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: paleta.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: paleta.primary, width: 1.6),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: paleta.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: paleta.primary,
          side: BorderSide(color: paleta.primary.withValues(alpha: 0.68)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: paleta.primary),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: paleta.primary,
        foregroundColor: Colors.white,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: paleta.primary,
        linearTrackColor: paleta.primary.withValues(alpha: 0.10),
      ),

      chipTheme: base.chipTheme.copyWith(
        selectedColor: paleta.primary,
        secondarySelectedColor: paleta.primary,
        side: BorderSide(color: paleta.border),
      ),

      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: Color.lerp(paleta.primary, Colors.black, 0.55),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }

          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return paleta.primary;
          }

          return null;
        }),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: paleta.primary,
        textColor: textoPrincipal,
        subtitleTextStyle: const TextStyle(color: textoSecundario),
      ),
    );
  }
}
