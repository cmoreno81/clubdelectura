import 'package:flutter/material.dart';

import '../models/estado_club.dart';

class EstadoClubFactory {
  static EstadoClub fromApi(String estado) {
    final estadoNormalizado = estado.trim().toUpperCase();
    switch (estadoNormalizado) {
      case 'PREPARANDO':
        return const EstadoClub(
          estado: EstadoClubTipo.preparando,
          titulo: 'La próxima aventura está cerca',
          mensaje: 'El club sigue disfrutando de la lectura actual.',
          icono: '🌙',
          color: const Color(0xFFE8EDF5),
        );

      case 'VOTACION':
        return const EstadoClub(
          estado: EstadoClubTipo.votacion,
          titulo: '¡Clubvisión está abierta!',
          mensaje: 'Ya puedes elegir la próxima aventura del club.',
          icono: '🟢',
          permiteVotar: true,
          color: const Color(0xFFE6F6EA),
        );

      case 'ULTIMAS_HORAS':
        return const EstadoClub(
          estado: EstadoClubTipo.ultimasHoras,
          titulo: '⏳ Últimas horas',
          mensaje: 'Queda muy poco para conocer la próxima lectura.',
          icono: '🟠',
          permiteVotar: true,
          mostrarCuentaAtras: true,
          color: const Color(0xFFFFF3E0),
        );
      case 'RESULTADOS':
      case 'GALA':
        return const EstadoClub(
          estado: EstadoClubTipo.gala,
          titulo: '🏆 La Gala del Club',
          mensaje: 'Ya tenemos una nueva lectura.',
          icono: '🏆',
          mostrarGanador: true,
          color: const Color(0xFFFFF8E1),
        );

      case 'LECTURA':
        return const EstadoClub(
          estado: EstadoClubTipo.lectura,
          titulo: '📖 Estamos leyendo',
          mensaje: 'Es momento de disfrutar la lectura elegida.',
          icono: '📖',
          color: const Color(0xFFEAF2FF),
        );

      default:
        return const EstadoClub(
          estado: EstadoClubTipo.preparando,
          titulo: 'ClubReads',
          mensaje: 'Preparando la próxima aventura.',
          icono: '📚',
          color: Colors.white,
        );
    }
  }
}
