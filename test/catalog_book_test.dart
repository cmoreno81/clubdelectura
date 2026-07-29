import 'package:club_lectura_app/models/catalog_book.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta un libro local que ya pertenece a la usuaria', () {
    final book = CatalogBook.fromJson({
      'id': 'book-1',
      'origen': 'CLUBREADS',
      'titulo': 'Inmortal Dark',
      'autores': ['Tigest Girma'],
      'enMiBiblioteca': true,
      'estado': 'FINALIZADO',
      'paginas': 400,
    });

    expect(book.title, 'Inmortal Dark');
    expect(book.authorLabel, 'Tigest Girma');
    expect(book.inMyLibrary, isTrue);
    expect(book.status, 'FINALIZADO');
    expect(book.isExternal, isFalse);
  });

  test('interpreta un resultado externo sin inventar datos ausentes', () {
    final book = CatalogBook.fromJson({
      'id': 'google-1',
      'origen': 'GOOGLE',
      'titulo': 'Immortal Consequences',
      'autores': <String>[],
      'enMiBiblioteca': false,
    });

    expect(book.authorLabel, 'Autor desconocido');
    expect(book.pages, isNull);
    expect(book.publicationYear, isNull);
    expect(book.isExternal, isTrue);
  });

  test('al añadir conserva el resto de los datos del catálogo', () {
    final original = CatalogBook.fromJson({
      'id': 'google-1',
      'origen': 'GOOGLE',
      'titulo': 'Immortal Consequences',
      'autores': ['Tigest Girma'],
      'isbn': '9780000000000',
      'enMiBiblioteca': false,
    });

    final added = original.copyWith(
      inMyLibrary: true,
      status: 'PENDIENTE',
    );

    expect(added.inMyLibrary, isTrue);
    expect(added.status, 'PENDIENTE');
    expect(added.isbn, original.isbn);
  });
}
