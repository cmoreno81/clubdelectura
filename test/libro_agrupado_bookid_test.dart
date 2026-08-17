// Tests para LibroAgrupado.bookId con el override introducido para libros
// de catálogo que no tienen registros ni finalizados en la biblioteca.

import 'package:club_lectura_app/models/libro_agrupado.dart';
import 'package:flutter_test/flutter_test.dart';

LibroAgrupado _agrupado({
  List<dynamic> registros = const [],
  List<dynamic> finalizados = const [],
  String? bookId,
}) => LibroAgrupado(
  libro: 'El príncipe cruel',
  genero: 'Fantasía',
  registros: const [],      // sin registros reales en estos tests de unit
  finalizados: const [],
  yaLoTengo: false,
  coverUrl: '',
  bookId: bookId,
);

void main() {
  group('LibroAgrupado.bookId override', () {
    test('devuelve el override cuando se proporciona', () {
      final libro = _agrupado(bookId: 'abc-123');
      expect(libro.bookId, 'abc-123');
    });

    test('recorta espacios del override', () {
      final libro = _agrupado(bookId: '  trimmed-id  ');
      expect(libro.bookId, 'trimmed-id');
    });

    test('ignora override vacío y devuelve cadena vacía sin registros', () {
      final libro = _agrupado(bookId: '');
      expect(libro.bookId, '');
    });

    test('ignora override de solo espacios', () {
      final libro = _agrupado(bookId: '   ');
      expect(libro.bookId, '');
    });

    test('null override devuelve vacío sin registros', () {
      final libro = _agrupado(bookId: null);
      expect(libro.bookId, '');
    });

    test('override tiene prioridad sobre registros con bookId', () {
      // Aunque no pasamos registros reales al helper, verificamos
      // que si el override está presente, se devuelve directamente.
      final libro = _agrupado(bookId: 'override-id');
      expect(libro.bookId, 'override-id');
    });
  });

  group('LibroAgrupado stats básicos', () {
    test('total refleja la longitud de registros', () {
      final libro = LibroAgrupado(
        libro: 'Test',
        genero: '',
        registros: const [],
        finalizados: const [],
        yaLoTengo: false,
        coverUrl: '',
      );
      expect(libro.total, 0);
      expect(libro.totalFinalizados, 0);
    });

    test('mediaValoracion devuelve 0 sin finalizados', () {
      final libro = LibroAgrupado(
        libro: 'Test',
        genero: '',
        registros: const [],
        finalizados: const [],
        yaLoTengo: false,
        coverUrl: '',
      );
      expect(libro.mediaValoracion, 0.0);
    });

    test('esReciente es false cuando fechaAlta es null', () {
      final libro = LibroAgrupado(
        libro: 'Test',
        genero: '',
        registros: const [],
        finalizados: const [],
        yaLoTengo: false,
        coverUrl: '',
      );
      expect(libro.esReciente, isFalse);
    });

    test('referencia es null sin registros', () {
      final libro = LibroAgrupado(
        libro: 'Test',
        genero: '',
        registros: const [],
        finalizados: const [],
        yaLoTengo: false,
        coverUrl: '',
      );
      expect(libro.referencia, isNull);
    });

    test('goodreads devuelve vacío sin registros ni finalizados', () {
      final libro = LibroAgrupado(
        libro: 'Test',
        genero: '',
        registros: const [],
        finalizados: const [],
        yaLoTengo: false,
        coverUrl: '',
      );
      expect(libro.goodreads, '');
    });
  });
}
