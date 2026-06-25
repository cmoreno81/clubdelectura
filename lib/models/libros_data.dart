import 'libro.dart';
import 'libro_finalizado.dart';

class LibrosData {

  final List<Libro> libros;

  final List<LibroFinalizado> finalizados;

  LibrosData({
    required this.libros,
    required this.finalizados,
  });
}