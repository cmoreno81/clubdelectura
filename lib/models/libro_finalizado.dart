class LibroFinalizado {
  final String bookId;

  final String usuario;
  final String libro;
  final String autor;
  final String genero;
  final String saga;
  final String numSaga;
  final String autoconclusivo;
  final String valoracion;
  /// Nivel picante opcional ('' = sin especificar), como cadena de 🌶️.
  final String picante;
  final String formato;
  final String idioma;
  final String resena;
  final String coverUrl;
  final String goodreads;
  final DateTime? fechaAlta;
  /// Cuándo se terminó de leer (Reading.finishedAt en el backend).
  final DateTime? finishedAt;
  final String avatarUrl;
  final int? paginas;
  final bool yaLoTengo;
  /// true cuando el registro llegó por importación (Goodreads, Bookmory…).
  final bool isImported;
  /// true si esta lectora comparte club con quien consulta (ver [Libro]).
  final bool mismoClub;

  const LibroFinalizado({
    required this.bookId,
    required this.usuario,
    required this.libro,
    this.autor = '',
    required this.genero,
    required this.saga,
    required this.numSaga,
    required this.autoconclusivo,
    required this.valoracion,
    this.picante = '',
    this.formato = '',
    this.idioma = '',
    required this.resena,
    required this.coverUrl,
    this.goodreads = '',
    required this.fechaAlta,
    this.finishedAt,
    required this.avatarUrl,
    required this.paginas,
    this.yaLoTengo = false,
    this.isImported = false,
    this.mismoClub = true,
  });

  factory LibroFinalizado.fromJson(Map<String, dynamic> json) {
    return LibroFinalizado(
      bookId: json['bookId']?.toString() ?? json['id']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? '',
      libro: json['libro']?.toString() ?? '',
      autor: json['autor']?.toString() ?? json['author']?.toString() ?? '',
      genero: json['genero']?.toString() ?? '',
      saga: json['saga']?.toString() ?? '',
      numSaga: json['numSaga']?.toString() ?? '',
      autoconclusivo: json['autoconclusivo']?.toString() ?? '',
      valoracion: json['valoracion']?.toString() ?? '',
      picante: json['picante']?.toString() ?? '',
      formato: json['formato']?.toString() ?? '',
      idioma: json['idioma']?.toString() ?? json['language']?.toString() ?? '',
      resena: json['resena']?.toString() ?? json['review']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
      goodreads:
          json['goodreads']?.toString() ??
          json['goodreadsUrl']?.toString() ??
          '',
      fechaAlta: DateTime.tryParse(json['fechaAlta']?.toString() ?? ''),
      finishedAt: DateTime.tryParse(json['fecha']?.toString() ?? ''),
      avatarUrl:
          json['avatarUrl']?.toString() ??
          json['fotoUrl']?.toString() ??
          json['photoUrl']?.toString() ??
          '',
      paginas:
          (json['paginas'] as num?)?.toInt() ??
          (json['totalPages'] as num?)?.toInt(),
      yaLoTengo: json['yaLoTengo'] as bool? ?? false,
      isImported: json['isImported'] as bool? ?? false,
      mismoClub: json['mismoClub'] as bool? ?? true,
    );
  }
}
