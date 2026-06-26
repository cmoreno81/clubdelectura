class NuevoLibro {
  final String usuario;
  final String libro;
  final String genero;
  final String saga;
  final String numSaga;
  final String autoconclusivo;
  final String prioridad;

  NuevoLibro({
    required this.usuario,
    required this.libro,
    required this.genero,
    required this.saga,
    required this.numSaga,
    required this.autoconclusivo,
    required this.prioridad,
  });

  Map<String, dynamic> toJson() {
    return {
      'usuario': usuario,
      'libro': libro,
      'genero': genero,
      'saga': saga,
      'numSaga': numSaga,
      'autoconclusivo': autoconclusivo,
      'prioridad': prioridad,
    };
  }
}
