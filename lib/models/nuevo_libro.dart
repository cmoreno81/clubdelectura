class NuevoLibro {
  final String? bookId;
  final String usuario;
  final String libro;
  final String autor;
  final String genero;
  final String saga;
  final String numSaga;
  final String autoconclusivo;
  final String prioridad;
  final String formato;

  final String goodreads;
  final String coverUrl;
  final int? paginas;

  NuevoLibro({
    this.bookId,
    required this.usuario,
    required this.libro,
    this.autor = '',
    required this.genero,
    required this.saga,
    required this.numSaga,
    required this.autoconclusivo,
    required this.prioridad,
    this.formato = '',
    this.goodreads = '',
    this.coverUrl = '',
    this.paginas,
  });

  Map<String, dynamic> toJson() {
    return {
      if (bookId != null && bookId!.trim().isNotEmpty) 'bookId': bookId!.trim(),

      'usuario': usuario,
      'libro': libro,
      if (autor.trim().isNotEmpty) 'autor': autor.trim(), // ← omitir si vacío
      'genero': genero,
      'saga': saga,
      'numSaga': numSaga,
      'autoconclusivo': autoconclusivo,
      if (prioridad.trim().isNotEmpty)
        'prioridad': prioridad, // ← omitir si vacío
      if (formato.trim().isNotEmpty) 'formato': formato, // ← omitir si vacío
      if (goodreads.trim().isNotEmpty) 'goodreads': goodreads.trim(),
      if (coverUrl.trim().isNotEmpty) 'coverUrl': coverUrl.trim(),
      if (paginas != null && paginas! > 0)
        'paginas': paginas, // ← omitir si null o 0
    };
  }
}
