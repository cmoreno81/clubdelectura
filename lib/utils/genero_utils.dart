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
  'Novela contemporánea',
  'Novela histórica',
  'Ciencia ficción',
  'Terror',
  'Gótico',
  'Cómic',
  'No ficción',
  'Infantil',
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
    case 'comic':
    case 'cómic':
      return '💬';
    case 'no ficcion':
    case 'no ficción':
      return '🧠';
    case 'infantil':
      return '🎈';
    default:
      return '📚';
  }
}
