class LibroFinalizado {
  final String bookId;

  final String usuario;
  final String libro;
  final String genero;
  final String saga;
  final String numSaga;
  final String autoconclusivo;
  final String valoracion;
  final String resena;
  final String coverUrl;

  const LibroFinalizado({
    required this.bookId,
    required this.usuario,
    required this.libro,
    required this.genero,
    required this.saga,
    required this.numSaga,
    required this.autoconclusivo,
    required this.valoracion,
    required this.resena,
    required this.coverUrl,
  });

  factory LibroFinalizado.fromJson(Map<String, dynamic> json) {
    return LibroFinalizado(
      bookId: json['bookId']?.toString() ?? json['id']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? '',
      libro: json['libro']?.toString() ?? '',
      genero: json['genero']?.toString() ?? '',
      saga: json['saga']?.toString() ?? '',
      numSaga: json['numSaga']?.toString() ?? '',
      autoconclusivo: json['autoconclusivo']?.toString() ?? '',
      valoracion: json['valoracion']?.toString() ?? '',
      resena: json['resena']?.toString() ?? json['review']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
    );
  }
}
