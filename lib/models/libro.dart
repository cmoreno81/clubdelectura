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
  final bool yaLoTengo;
  final String goodreads;

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
    required this.yaLoTengo,
    required this.goodreads,
  });

  factory Libro.fromJson(Map<String, dynamic> json) {
    return Libro(
      usuario: json['usuario']?.toString() ?? '',
      libro: json['libro']?.toString() ?? '',
      genero: json['genero']?.toString() ?? '',
      saga: json['saga']?.toString() ?? '',
      numSaga: json['numSaga']?.toString() ?? '',
      autoconclusivo: json['autoconclusivo']?.toString() ?? '',
      prioridad: json['prioridad']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      valoracion: json['valoracion']?.toString() ?? '',
      yaLoTengo: json["yaLoTengo"] ?? false,
      goodreads: json['goodreads']?.toString() ?? '',
    );
  }
}
