/// Géneros que ofrece el selector de corrección rápida desde la tarjeta.
/// Usan la misma grafía que reconoce [iconoGenero].
const generosSoportados = [
  'Fantasía',
  'Romantasy',
  'Romance',
  'Dark Romance',
  'Mafia Romance',
  'Paranormal',
  'Thriller',
  'Novela negra',
  'Dark Academia',
  'Drama',
  'Clásicos',
  'Distopía',
  'Novela contemporánea',
  'Novela histórica',
  'Ciencia ficción',
  'Terror',
  'Gótico',
  'Cómic',
  'No ficción',
  'Infantil',
  'Juvenil',
  'Poesía',
  'Narrativa',
  'Grimdark',
];

String iconoGenero(String genero) {
  switch (genero.toLowerCase()) {
    case 'fantasía':
      return '🐉';
    case 'novela negra':
      return '🔪';
    case 'romance':
      return '💕';
    case 'terror':
      return '👻';
    case 'gótico':
    case 'gotico':
      return '🦇';
    case 'ciencia ficción':
      return '🚀';
    case 'novela contemporánea':
      return '📖';
    case 'novela histórica':
      return '🏰';
    case 'romantasy':
      return '🦄';
    case 'thriller':
      return '🕵️';
    case 'dark academia':
      return '🎭';
    case 'dark romance':
      return '🖤';
    case 'mafia romance':
      return '🌹🔫';
    case 'romance paranormal':
    case 'paranormal':
      return '🧛';
    case 'drama':
      return '😭';
    case 'clásicos':
      return '📜';
    case 'distopía':
    case 'distopia':
      return '🌇';
    case 'comic':
    case 'cómic':
      return '💬';
    case 'no ficcion':
    case 'no ficción':
      return '🧠';
    case 'narrativa':
      return '📚';
    case 'grimdark':
      return '⚔️';
    case 'infantil':
      return '🎈';
    case 'juvenil':
      return '🎒';
    case 'poesía':
    case 'poesia':
      return '🪶';
    default:
      return '📚';
  }
}

/// Lee la lista `generos` del servidor (principal primero). Los servidores
/// o respuestas antiguas no la traen: se queda vacía y se usa `genero`.
List<String> leerGeneros(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// Máximo de géneros que puede tener un libro.
const maxGenerosLibro = 3;

/// El género con la grafía de [validos] si coincide sin distinguir mayúsculas
/// («Ciencia Ficción» → «Ciencia ficción»); si no coincide, tal cual está.
String canonicoGenero(String genero, Iterable<String> validos) {
  final limpio = genero.trim();
  for (final v in validos) {
    if (v.toLowerCase() == limpio.toLowerCase()) return v;
  }
  return limpio;
}
