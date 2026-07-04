import 'comentario_lectura.dart';

class ComentariosCapitulo {
  final String capitulo;

  final List<ComentarioLectura> comentarios;

  ComentariosCapitulo({required this.capitulo, required this.comentarios});

  factory ComentariosCapitulo.fromJson(Map<String, dynamic> json) {
    return ComentariosCapitulo(
      capitulo: json["capitulo"] ?? "",

      comentarios: (json["comentarios"] as List? ?? [])
          .map((e) => ComentarioLectura.fromJson(e))
          .toList(),
    );
  }
}
