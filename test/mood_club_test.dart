import 'package:club_lectura_app/models/mood_club.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActividadClub', () {
    test('lee los datos del libro de una crónica de finalización', () {
      final actividad = ActividadClub.fromJson({
        'icono': '📚',
        'texto': 'Cristina terminó un libro',
        'tipo': 'LIBRO',
        'bookId': 'book-42',
        'libro': 'Un libro',
        'coverUrl': 'https://example.com/cover.jpg',
        'capitulo': '',
      });

      expect(actividad.tipo, 'LIBRO');
      expect(actividad.bookId, 'book-42');
      expect(actividad.libro, 'Un libro');
      expect(actividad.coverUrl, 'https://example.com/cover.jpg');
    });

    test('mantiene compatibles las crónicas antiguas sin identificador', () {
      final actividad = ActividadClub.fromJson({
        'icono': '📚',
        'texto': 'Cristina terminó un libro',
        'tipo': 'LIBRO',
        'libro': 'Un libro',
        'capitulo': '',
      });

      expect(actividad.bookId, isEmpty);
      expect(actividad.coverUrl, isEmpty);
      expect(actividad.libro, 'Un libro');
    });
  });
}
