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
          icono: Icons.nights_stay,
          iconColor: Colors.amber,
          contenido: ContenidoClub.preparando,
          color: const Color(0xFFE8EDF5),
        );

      case 'VOTACION':
        return const EstadoClub(
          estado: EstadoClubTipo.votacion,
          titulo: '¡Clubvisión está abierta!',
          mensaje: 'Ya puedes elegir la próxima aventura del club.',
          icono: Icons.how_to_vote,
          iconColor: Colors.green,
          contenido: ContenidoClub.candidatas,
          permiteVotar: true,
          color: const Color(0xFFE6F6EA),
        );

      case 'ULTIMAS_HORAS':
        return const EstadoClub(
          estado: EstadoClubTipo.ultimasHoras,
          titulo: 'Últimas horas',
          mensaje: 'Queda muy poco para conocer la próxima lectura.',
          icono: Icons.hourglass_top,
          iconColor: Colors.amber,
          contenido: ContenidoClub.candidatas,
          permiteVotar: true,
          mostrarCuentaAtras: true,
          color: const Color(0xFFFFF3E0),
        );
      case 'RESULTADOS':
      case 'GALA':
        return const EstadoClub(
          estado: EstadoClubTipo.gala,
          titulo: 'La Gala del Club',
          mensaje: 'Ya tenemos una nueva lectura.',
          icono: Icons.emoji_events,
          iconColor: Colors.amber,
          contenido: ContenidoClub.ganador,
          mostrarGanador: true,
          color: const Color(0xFFFFF8E1),
        );

      case 'LECTURA':
        return const EstadoClub(
          estado: EstadoClubTipo.lectura,
          titulo: 'Estamos leyendo',
          mensaje: 'Es momento de disfrutar la lectura elegida.',
          icono: Icons.menu_book,
          iconColor: Colors.indigo,
          contenido: ContenidoClub.lectura,
          color: Color(0xFFF3F0FF),
        );

      default:
        return const EstadoClub(
          estado: EstadoClubTipo.preparando,
          titulo: 'ClubReads',
          mensaje: 'Preparando la próxima aventura.',
          icono: Icons.notification_important,
          iconColor: Colors.amber,
          contenido: ContenidoClub.preparando,
          color: const Color(0xFFEAF2FF),
        );
    }
  }
}
