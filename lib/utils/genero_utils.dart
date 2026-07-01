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
    case 'drama':
      return '😭';
    case 'clásicos':
      return '📜';
    default:
      return '📚';
  }
}
