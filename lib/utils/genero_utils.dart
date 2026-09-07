/// Géneros que ofrece el selector de corrección rápida desde la tarjeta.
/// Usan la misma grafía que reconoce [iconoGenero].
const generosSoportados = [
  'Fantasía',
  'Romantasy',
  'Romance',
  'Dark Romance',
  'Mafia Romance',
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
  'Poesía',
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
    case 'infantil':
      return '🎈';
    case 'poesía':
    case 'poesia':
      return '🪶';
    default:
      return '📚';
  }
}
