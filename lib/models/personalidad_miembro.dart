/// Resultado del quiz de personalidad lectora de un miembro del club.
class PersonalidadMiembro {
  const PersonalidadMiembro({
    required this.usuario,
    required this.avatarUrl,
    required this.arquetipo,
  });

  final String usuario;
  final String avatarUrl;
  final String arquetipo;

  factory PersonalidadMiembro.fromJson(Map<String, dynamic> json) =>
      PersonalidadMiembro(
        usuario: json['usuario']?.toString() ?? '',
        avatarUrl: json['avatarUrl']?.toString() ?? '',
        arquetipo: json['arquetipo']?.toString() ?? '',
      );

  /// Emoji representativo del arquetipo.
  String get emoji => switch (arquetipo) {
    'nocturna' => '🌙',
    'maratonista' => '📚',
    'romantica' => '💕',
    'reflexiva' => '🧠',
    'imparable' => '⚡',
    'estetica' => '🎨',
    _ => '📖',
  };

  /// Nombre legible del arquetipo.
  String get nombreArquetipo => switch (arquetipo) {
    'nocturna' => 'La Lectora Nocturna',
    'maratonista' => 'La Maratonista de Sagas',
    'romantica' => 'La Romántica Empedernida',
    'reflexiva' => 'La Lectora Reflexiva',
    'imparable' => 'La Lectora Imparable',
    'estetica' => 'La Esteta del Libro',
    _ => 'Lectora',
  };

  /// Color representativo del arquetipo (gradiente principal).
  ({int start, int end}) get colores => switch (arquetipo) {
    'nocturna' => (start: 0xFF1A0933, end: 0xFF5C2E84),
    'maratonista' => (start: 0xFF1A3A1A, end: 0xFF4A9E4A),
    'romantica' => (start: 0xFF4A1A2E, end: 0xFFBF5480),
    'reflexiva' => (start: 0xFF1A2A4A, end: 0xFF4A6FBF),
    'imparable' => (start: 0xFF3A2A00, end: 0xFFD4A800),
    'estetica' => (start: 0xFF2E1A3A, end: 0xFF9E5FBF),
    _ => (start: 0xFF3A1A4A, end: 0xFF7B3FA0),
  };
}
