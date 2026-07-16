import 'libro.dart';
import 'libro_finalizado.dart';

class LibroAgrupado {
  final String libro;
  final String genero;

  final List<Libro> registros;

  final List<LibroFinalizado> finalizados;
  bool yaLoTengo;
  String coverUrl;

  LibroAgrupado({
    required this.libro,
    required this.genero,
    required this.registros,
    required this.finalizados,
    required this.yaLoTengo,
    required this.coverUrl,
  });

  int get total => registros.length;

  int get totalFinalizados => finalizados.length;

  double get mediaValoracion {
    if (finalizados.isEmpty) {
      return 0;
    }

    final valores = finalizados
        .map((f) => _valorNumerico(f.valoracion))
        .where((v) => v > 0)
        .toList();

    if (valores.isEmpty) {
      return 0;
    }

    return valores.reduce((a, b) => a + b) / valores.length;
  }

  double _valorNumerico(String valoracion) {
    final texto = valoracion.trim().replaceAll('⭐️', '⭐').replaceAll(',', '.');

    if (texto.isEmpty || texto == '😞') {
      return 0;
    }

    final numeroDirecto = double.tryParse(texto);

    if (numeroDirecto != null) {
      return ((numeroDirecto.clamp(0, 5)).toDouble() * 2).round() / 2;
    }

    final estrellasCompletas = RegExp('⭐').allMatches(texto).length;
    final tieneMedia = texto.contains('½');

    final resultado = estrellasCompletas + (tieneMedia ? 0.5 : 0);

    return ((resultado.clamp(0, 5)).toDouble() * 2).round() / 2;
  }

  String get bookId {
    for (final registro in registros) {
      if (registro.bookId.trim().isNotEmpty) {
        return registro.bookId.trim();
      }
    }

    for (final finalizado in finalizados) {
      if (finalizado.bookId.trim().isNotEmpty) {
        return finalizado.bookId.trim();
      }
    }

    return '';
  }

  DateTime? get fechaAlta {
    final fechas = <DateTime>[];

    for (final registro in registros) {
      final fecha = registro.fechaAlta;

      if (fecha != null) {
        fechas.add(fecha);
      }
    }

    for (final finalizado in finalizados) {
      final fecha = finalizado.fechaAlta;

      if (fecha != null) {
        fechas.add(fecha);
      }
    }

    if (fechas.isEmpty) {
      return null;
    }

    // Primera incorporación del libro al catálogo.
    fechas.sort();

    return fechas.first;
  }

  bool get esReciente {
    final fecha = fechaAlta;

    if (fecha == null) {
      return false;
    }

    final diferencia = DateTime.now().difference(fecha);

    return !diferencia.isNegative && diferencia.inDays <= 14;
  }

  Libro? get referencia {
    if (registros.isEmpty) return null;
    return registros.first;
  }
}
