/// Categorías fijas de los subrayadores del kit de lectura.
/// El orden coincide con el índice de color en [KitLecturaSeleccion.subrayadores].
class SubrayadorCategoria {
  const SubrayadorCategoria({
    required this.emoji,
    required this.nombre,
    required this.esCita,
  });

  final String emoji;
  final String nombre;

  /// Si `true`, el comentario enviado con esta categoría tendrá tipo QUOTE
  /// (texto en cursiva, formato de cita del libro).
  final bool esCita;
}

const List<SubrayadorCategoria> kSubrayadorCategorias = [
  SubrayadorCategoria(emoji: '⭐', nombre: 'Momento fav.', esCita: false),
  SubrayadorCategoria(emoji: '💭', nombre: 'Teoría', esCita: false),
  SubrayadorCategoria(emoji: '🗣️', nombre: 'Cita del libro', esCita: true),
  SubrayadorCategoria(emoji: '🧩', nombre: 'Personaje', esCita: false),
  SubrayadorCategoria(emoji: '⚡', nombre: 'Impacto', esCita: false),
];
