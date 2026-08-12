import 'package:flutter/material.dart';

/// Ruta para pantallas de detalle de libro.
///
/// A diferencia de [AppPageRoute] (duración cero), esta ruta usa una duración
/// corta que permite animar el Hero de la portada, manteniendo aun así
/// [allowSnapshotting: false] para evitar el parpadeo de iOS cuando la
/// pantalla anterior se refresca al recuperar foco.
class BookDetailPageRoute<T> extends MaterialPageRoute<T> {
  BookDetailPageRoute({required super.builder, super.settings})
    : super(allowSnapshotting: false);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 280);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade suave para la pantalla; el Hero anima la portada por su cuenta.
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeInOut,
      ),
      child: child,
    );
  }
}
