class NuevoLibro {
  final String? bookId;
  final String usuario;
  final String libro;
  final String genero;
  final String saga;
  final String numSaga;
  final String autoconclusivo;
  final String prioridad;

  final String goodreads;
  final String coverUrl;

  NuevoLibro({
    this.bookId,
    required this.usuario,
    required this.libro,
    required this.genero,
    required this.saga,
    required this.numSaga,
    required this.autoconclusivo,
    required this.prioridad,
    this.goodreads = '',
    this.coverUrl = '',
  });

  Map<String, dynamic> toJson() {
    return {
      if (bookId != null && bookId!.trim().isNotEmpty) 'bookId': bookId!.trim(),

      'usuario': usuario,
      'libro': libro,
      'genero': genero,
      'saga': saga,
      'numSaga': numSaga,
      'autoconclusivo': autoconclusivo,
      'prioridad': prioridad,
      'goodreads': goodreads.trim(),
      'coverUrl': coverUrl.trim(),
    };
  }
}
