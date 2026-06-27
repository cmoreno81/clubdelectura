import 'package:flutter/material.dart';

enum EstadoClubTipo { preparando, votacion, ultimasHoras, gala, lectura }

class EstadoClub {
  final EstadoClubTipo estado;

  final String titulo;
  final String mensaje;
  final String icono;

  final bool permiteVotar;
  final bool mostrarCuentaAtras;
  final bool mostrarGanador;

  final Color color;

  const EstadoClub({
    required this.estado,
    required this.titulo,
    required this.mensaje,
    required this.icono,
    required this.color,
    this.permiteVotar = false,
    this.mostrarCuentaAtras = false,
    this.mostrarGanador = false,
  });
}
