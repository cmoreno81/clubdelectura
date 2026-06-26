class LibroFinalizado {
  final String usuario;
  final String libro;
  final String genero;
  final String saga;
  final String numSaga;
  final String autoconclusivo;
  final String valoracion;

  LibroFinalizado({
    required this.usuario,
    required this.libro,
    required this.genero,
    required this.saga,
    required this.numSaga,
    required this.autoconclusivo,
    required this.valoracion,
  });

  factory LibroFinalizado.fromJson(Map<String, dynamic> json) {
    return LibroFinalizado(
      usuario: json['usuario'] ?? '',
      libro: json['libro'] ?? '',
      genero: json['genero'] ?? '',
      saga: json['saga'] ?? '',
      numSaga: json['numSaga'] ?? '',
      autoconclusivo: json['autoconclusivo'] ?? '',
      valoracion: json['valoracion']?.toString() ?? '',
    );
  }
}
