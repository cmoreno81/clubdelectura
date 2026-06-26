class Libro {
  final String usuario;
  final String libro;
  final String genero;
  final String saga;
  final String numSaga;
  final String autoconclusivo;
  final String prioridad;
  final String estado;
  final String valoracion;

  Libro({
    required this.usuario,
    required this.libro,
    required this.genero,
    required this.saga,
    required this.numSaga,
    required this.autoconclusivo,
    required this.prioridad,
    required this.estado,
    required this.valoracion,
  });

  factory Libro.fromJson(Map<String, dynamic> json) {
    return Libro(
      usuario: json['usuario'] ?? '',
      libro: json['libro'] ?? '',
      genero: json['genero'] ?? '',
      saga: json['saga'] ?? '',
      numSaga: json['numSaga'] ?? '',
      autoconclusivo: json['autoconclusivo'] ?? '',
      prioridad: json['prioridad'] ?? '',
      estado: json['estado'] ?? '',
      valoracion: json['valoracion']?.toString() ?? '',
    );
  }
}
