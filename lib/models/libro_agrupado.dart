import 'libro.dart';
import 'libro_finalizado.dart';

class LibroAgrupado {

  final String libro;
  final String genero;

  final List<Libro> registros;

  final List<LibroFinalizado> finalizados;

  LibroAgrupado({
    required this.libro,
    required this.genero,
    required this.registros,
    required this.finalizados,
  });

  int get total =>
      registros.length;

  int get totalFinalizados =>
      finalizados.length;

  double get mediaValoracion {

    if (finalizados.isEmpty) {
      return 0;
    }

    final valores =
        finalizados
            .map(
              (f) => _valorNumerico(
                f.valoracion,
              ),
            )
            .where(
              (v) => v > 0,
            )
            .toList();

    if (valores.isEmpty) {
      return 0;
    }

    return valores.reduce(
          (a, b) => a + b,
        ) /
        valores.length;
  }

  double _valorNumerico(
    String valoracion,
  ) {

    switch (
        valoracion.trim()) {

      case '⭐':
      case '⭐️':
        return 1;

      case '⭐⭐':
      case '⭐️⭐️':
        return 2;

      case '⭐⭐⭐':
      case '⭐️⭐️⭐️':
        return 3;

      case '⭐⭐⭐⭐':
      case '⭐️⭐️⭐️⭐️':
        return 4;

      case '⭐⭐⭐⭐⭐':
      case '⭐️⭐️⭐️⭐️⭐️':
        return 5;

      default:
        return 0;
    }
  }
}