import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Espacio a dejar al final de cualquier contenido con scroll que viva bajo
/// un [FloatingNavBar] (`extendBody: true`), para que la última tarjeta no
/// quede tapada por la píldora al hacer scroll hasta el final — cubre su
/// altura + el margen inferior + el área segura del dispositivo, con un
/// poco de aire extra.
const kFloatingNavClearance = 140.0;

/// Envuelve un [NavigationBar] (u otro contenido de menú inferior, p. ej. un
/// Row con un botón adicional + NavigationBar) en una píldora flotante —
/// separada de los bordes de la pantalla, con esquinas redondeadas y sombra —
/// al estilo del menú inferior de WhatsApp, en vez de una barra convencional
/// pegada de borde a borde.
///
/// No reimplementa la selección de pestañas ni el comportamiento de las
/// etiquetas: sigue siendo un [NavigationBar] real por dentro (accesibilidad,
/// ripple y `labelBehavior` intactos), solo cambia el "marco" que lo rodea.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.child, this.height = 64});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final navTheme = Theme.of(context).navigationBarTheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.midnight.withValues(alpha: .18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: navTheme.copyWith(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              height: height,
              indicatorShape: const StadiumBorder(),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
