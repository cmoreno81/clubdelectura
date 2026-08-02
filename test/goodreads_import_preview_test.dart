import 'package:club_lectura_app/models/goodreads_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta las coincidencias ofrecidas para una fila a revisar', () {
    final preview = GoodreadsImportPreview.fromJson({
      'resumen': {'total': 1, 'paraRevisar': 1},
      'libros': [
        {
          'index': 7,
          'titulo': 'Libro importado',
          'autor': 'Autora',
          'accion': 'REVISAR',
          'mensaje': 'Hay varias coincidencias posibles.',
          'candidatos': [
            {
              'bookId': 'book-1',
              'titulo': 'Libro existente',
              'autor': 'Autora',
              'isbn': '9781234567890',
              'coverUrl': 'https://example.com/cover.jpg',
            },
          ],
        },
      ],
    });

    final book = preview.books.single;
    expect(book.action, 'REVISAR');
    expect(book.canImport, isFalse);
    expect(book.candidates.single.bookId, 'book-1');
    expect(book.candidates.single.isbn, '9781234567890');
    expect(book.candidates.single.coverUrl, contains('cover.jpg'));
  });
}
