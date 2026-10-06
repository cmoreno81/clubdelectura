import 'package:flutter/material.dart';

/// Nombres, emojis e iconos de los formatos de lectura: **Papel · Ebook ·
/// Audiolibro**. Es la única fuente de estos textos en la app (biblioteca,
/// lista de deseos, estadísticas y botones de compra), para que el mismo
/// formato no se llame de dos maneras. Los códigos que viajan al servidor
/// (`FISICO`, `DIGITAL`, `AUDIOLIBRO`, `PHYSICAL`…) no cambian.
class FormatoLibro {
  FormatoLibro._();

  static const papel = 'Papel';
  static const ebook = 'Ebook';
  static const audiolibro = 'Audiolibro';

  static const emojiPapel = '📖';
  static const emojiEbook = '📱';
  static const emojiAudiolibro = '🎧';

  /// Formato canónico (`papel`, `ebook`, `audio`) de cualquier código o nombre
  /// antiguo; null si no es ninguno de los tres.
  static String? normalizar(String? valor) {
    switch ((valor ?? '').trim().toUpperCase()) {
      case 'FISICO':
      case 'FÍSICO':
      case 'PHYSICAL':
      case 'PAPEL':
        return 'papel';
      case 'DIGITAL':
      case 'EBOOK':
        return 'ebook';
      case 'AUDIOLIBRO':
      case 'AUDIOBOOK':
      case 'AUDIO':
        return 'audio';
    }
    return null;
  }

  /// Nombre a mostrar. Si el valor no es un formato conocido se devuelve tal cual.
  static String etiqueta(String? valor) => switch (normalizar(valor)) {
    'papel' => papel,
    'ebook' => ebook,
    'audio' => audiolibro,
    _ => valor ?? '',
  };

  static String emoji(String? valor) => switch (normalizar(valor)) {
    'papel' => emojiPapel,
    'ebook' => emojiEbook,
    'audio' => emojiAudiolibro,
    _ => '',
  };

  static IconData icono(String? valor) => switch (normalizar(valor)) {
    'papel' => Icons.menu_book_rounded,
    'ebook' => Icons.tablet_mac_rounded,
    'audio' => Icons.headphones_rounded,
    _ => Icons.book_rounded,
  };

  /// "7 en papel", "3 ebooks", "1 audiolibro" (para los resúmenes con contadores).
  static String conteo(String formato, int n) => switch (normalizar(formato)) {
    'papel' => '$n en papel',
    'ebook' => '$n ebook${n == 1 ? '' : 's'}',
    'audio' => '$n audiolibro${n == 1 ? '' : 's'}',
    _ => '$n',
  };
}
