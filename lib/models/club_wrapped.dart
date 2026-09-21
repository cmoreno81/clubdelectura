class LibroPorPersona {
  final String userId;
  final String nombre;
  final String? avatarUrl;
  final int libros;

  const LibroPorPersona({
    required this.userId,
    required this.nombre,
    required this.avatarUrl,
    required this.libros,
  });

  factory LibroPorPersona.fromJson(Map<String, dynamic> json) {
    return LibroPorPersona(
      userId: json['userId'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      libros: (json['libros'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClubWrapped {
  final String clubId;
  final String clubNombre;
  final int year;
  final int miembros;
  final int totalLibros;
  final int totalPaginas;
  final int totalComentarios;
  final String? generoMasLeido;
  final int generoVeces;
  final List<LibroPorPersona> librosPorPersona;
  final String? libroDelAnioTitulo;
  final String? libroDelAnioCoverUrl;
  final String? favoritoTitulo;
  final String? favoritoCoverUrl;
  final int favoritoVotos;
  final int racha;

  const ClubWrapped({
    required this.clubId,
    required this.clubNombre,
    required this.year,
    required this.miembros,
    required this.totalLibros,
    required this.totalPaginas,
    required this.totalComentarios,
    required this.generoMasLeido,
    required this.generoVeces,
    required this.librosPorPersona,
    required this.libroDelAnioTitulo,
    required this.libroDelAnioCoverUrl,
    required this.favoritoTitulo,
    required this.favoritoCoverUrl,
    required this.favoritoVotos,
    required this.racha,
  });

  factory ClubWrapped.fromJson(Map<String, dynamic> json) {
    final genero = json['generoMasLeido'] as Map<String, dynamic>?;
    final libroDelAnio = json['libroDelAnio'] as Map<String, dynamic>?;
    final favorito = json['favoritoDelClub'] as Map<String, dynamic>?;
    return ClubWrapped(
      clubId: json['clubId'] as String? ?? '',
      clubNombre: json['clubNombre'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      miembros: (json['miembros'] as num?)?.toInt() ?? 0,
      totalLibros: (json['totalLibros'] as num?)?.toInt() ?? 0,
      totalPaginas: (json['totalPaginas'] as num?)?.toInt() ?? 0,
      totalComentarios: (json['totalComentarios'] as num?)?.toInt() ?? 0,
      generoMasLeido: genero?['nombre'] as String?,
      generoVeces: (genero?['veces'] as num?)?.toInt() ?? 0,
      librosPorPersona: (json['librosPorPersona'] as List<dynamic>? ?? [])
          .map((e) => LibroPorPersona.fromJson(e as Map<String, dynamic>))
          .toList(),
      libroDelAnioTitulo: libroDelAnio?['titulo'] as String?,
      libroDelAnioCoverUrl: libroDelAnio?['coverUrl'] as String?,
      favoritoTitulo: favorito?['titulo'] as String?,
      favoritoCoverUrl: favorito?['coverUrl'] as String?,
      favoritoVotos: (favorito?['votos'] as num?)?.toInt() ?? 0,
      racha: (json['racha'] as num?)?.toInt() ?? 0,
    );
  }
}
