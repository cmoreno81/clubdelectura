import 'package:flutter/material.dart';

/// Ruta de pantalla inmediata y opaca.
///
/// Evita que iOS conserve una captura de ambas pantallas durante la salida,
/// algo perceptible cuando la pantalla anterior se refresca al recuperar foco.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({required super.builder, super.settings})
    : super(allowSnapshotting: false);

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;
}
