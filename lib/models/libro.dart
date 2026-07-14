class Libro {
  final String bookId;

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
  final String coverUrl;

  const Libro({
    required this.bookId,
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
    required this.coverUrl,
  });

  factory Libro.fromJson(Map<String, dynamic> json) {
    return Libro(
      bookId: json['bookId']?.toString() ?? json['id']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? '',
      libro: json['libro']?.toString() ?? '',
      genero: json['genero']?.toString() ?? '',
      saga: json['saga']?.toString() ?? '',
      numSaga: json['numSaga']?.toString() ?? '',
      autoconclusivo: json['autoconclusivo']?.toString() ?? '',
      prioridad: json['prioridad']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      valoracion: json['valoracion']?.toString() ?? '',
      yaLoTengo: json['yaLoTengo'] as bool? ?? false,
      goodreads:
          json['goodreads']?.toString() ??
          json['goodreadsUrl']?.toString() ??
          '',
      coverUrl: json['coverUrl']?.toString() ?? '',
    );
  }

  Libro copyWith({
    String? bookId,
    String? usuario,
    String? libro,
    String? genero,
    String? saga,
    String? numSaga,
    String? autoconclusivo,
    String? prioridad,
    String? estado,
    String? valoracion,
    bool? yaLoTengo,
    String? goodreads,
    String? coverUrl,
  }) {
    return Libro(
      bookId: bookId ?? this.bookId,
      usuario: usuario ?? this.usuario,
      libro: libro ?? this.libro,
      genero: genero ?? this.genero,
      saga: saga ?? this.saga,
      numSaga: numSaga ?? this.numSaga,
      autoconclusivo: autoconclusivo ?? this.autoconclusivo,
      prioridad: prioridad ?? this.prioridad,
      estado: estado ?? this.estado,
      valoracion: valoracion ?? this.valoracion,
      yaLoTengo: yaLoTengo ?? this.yaLoTengo,
      goodreads: goodreads ?? this.goodreads,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }
}
