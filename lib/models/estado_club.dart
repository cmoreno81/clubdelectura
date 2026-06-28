import 'package:flutter/material.dart';

enum ContenidoClub { preparando, candidatas, ganador, lectura }

enum EstadoClubTipo { preparando, votacion, ultimasHoras, gala, lectura }

class EstadoClub {
  final EstadoClubTipo estado;

  final String titulo;
  final String mensaje;
  final IconData icono;
  final Color iconColor;
  final ContenidoClub contenido;

  final bool permiteVotar;
  final bool mostrarCuentaAtras;
  final bool mostrarGanador;

  final Color color;

  const EstadoClub({
    required this.estado,
    required this.titulo,
    required this.mensaje,
    required this.icono,
    required this.iconColor,
    required this.color,
    required this.contenido,
    this.permiteVotar = false,
    this.mostrarCuentaAtras = false,
    this.mostrarGanador = false,
  });
}
