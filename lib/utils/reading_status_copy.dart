import 'package:flutter/material.dart';

abstract final class ReadingStatusCopy {
  static String label(String status, {bool plural = false}) {
    switch (status.trim().toUpperCase()) {
      case 'LEYENDO':
        return 'Leyendo';
      case 'PAUSADO':
        return plural ? 'Tomando un respiro' : 'Necesito un respiro';
      case 'RELECTURA':
        return plural ? 'Otra vuelta' : 'Otra vuelta';
      case 'FINALIZADO':
      case 'TERMINADOS':
        return plural ? 'Historias terminadas' : 'Historia terminada';
      case 'ABANDONADO':
      case 'ABANDONED':
        return plural ? 'No eran para mí' : 'No era para mí';
      case 'PENDIENTE':
      default:
        return 'En mi estantería';
    }
  }

  static IconData icon(String status) {
    switch (status.trim().toUpperCase()) {
      case 'LEYENDO':
        return Icons.auto_stories_rounded;
      case 'PAUSADO':
        return Icons.nights_stay_outlined;
      case 'RELECTURA':
        return Icons.replay_rounded;
      case 'FINALIZADO':
      case 'TERMINADOS':
        return Icons.bookmark_added_rounded;
      case 'ABANDONADO':
      case 'ABANDONED':
        return Icons.heart_broken_rounded;
      case 'PENDIENTE':
      default:
        return Icons.bookmark_border_rounded;
    }
  }
}
