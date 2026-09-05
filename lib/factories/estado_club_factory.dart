import 'package:flutter/material.dart';

import '../models/estado_club.dart';

class EstadoClubFactory {
  static EstadoClub fromApi(String estado, {String ganador = ''}) {
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
          color: Color(0xFFE8EDF5),
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
          color: Color(0xFFE6F6EA),
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
          color: Color(0xFFFFF3E0),
        );
      case 'RESULTADOS':
      case 'GALA':
        final tieneGanador = ganador.trim().isNotEmpty;
        return EstadoClub(
          estado: EstadoClubTipo.gala,
          titulo: tieneGanador ? 'La Gala del Club' : 'Clubvisión',
          mensaje: tieneGanador
              ? 'Ya tenemos una nueva lectura.'
              : 'Este mes no hubo candidatos suficientes.',
          icono: tieneGanador ? Icons.emoji_events : Icons.event_busy_rounded,
          iconColor: tieneGanador ? Colors.amber : Colors.grey,
          contenido: ContenidoClub.ganador,
          mostrarGanador: tieneGanador,
          color: tieneGanador ? const Color(0xFFFFF8E1) : const Color(0xFFF5F5F5),
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

      // SIN_DATOS: sin candidatas este mes y sin ninguna lectura activa de
      // respaldo. Se trata igual que SIN_CANDIDATAS — si de verdad hay una
      // lectura activa, dashboard_page.dart ya decide mostrar la tarjeta
      // igualmente, y DirectorEscenas comprueba lecturaActual.ok para elegir
      // entre esa lectura y este estado "vacío".
      case 'SIN_DATOS':
      case 'SIN_CANDIDATAS':
        return const EstadoClub(
          estado: EstadoClubTipo.preparando,
          titulo: 'Sin libros candidatos este mes',
          mensaje:
              'Ningún libro tiene suficiente interés compartido para abrir la votación.',
          icono: Icons.library_books_outlined,
          iconColor: Colors.grey,
          contenido: ContenidoClub.sinCandidatas,
          color: Color(0xFFF5F5F5),
        );

      default:
        return const EstadoClub(
          estado: EstadoClubTipo.preparando,
          titulo: 'ClubReads',
          mensaje: 'Preparando la próxima aventura.',
          icono: Icons.notification_important,
          iconColor: Colors.amber,
          contenido: ContenidoClub.preparando,
          color: Color(0xFFEAF2FF),
        );
    }
  }
}
