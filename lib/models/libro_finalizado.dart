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
  final String formato;
  final String resena;
  final String coverUrl;
  final DateTime? fechaAlta;
  final String avatarUrl;
  final int? paginas;
  final bool yaLoTengo;

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
    this.formato = '',
    required this.resena,
    required this.coverUrl,
    required this.fechaAlta,
    required this.avatarUrl,
    required this.paginas,
    this.yaLoTengo = false,
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
      formato: json['formato']?.toString() ?? '',
      resena: json['resena']?.toString() ?? json['review']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
      fechaAlta: DateTime.tryParse(json['fechaAlta']?.toString() ?? ''),
      avatarUrl:
          json['avatarUrl']?.toString() ??
          json['fotoUrl']?.toString() ??
          json['photoUrl']?.toString() ??
          '',
      paginas:
          (json['paginas'] as num?)?.toInt() ??
          (json['totalPages'] as num?)?.toInt(),
      yaLoTengo: json['yaLoTengo'] as bool? ?? false,
    );
  }
}
