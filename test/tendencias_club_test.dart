import 'package:club_lectura_app/models/tendencias_club.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta portadas y avatares de tendencias', () {
    final data = TendenciasClub.fromJson({
      'titular': 'Fantasía marca el ritmo.',
      'narrador': 'El club está leyendo.',
      'totalLeyendo': 3,
      'generos': [
        {'nombre': 'Fantasía', 'total': 3},
      ],
      'libros': [
        {
          'id': 'book-1',
          'nombre': 'Una lectura',
          'total': 2,
          'coverUrl': 'https://example.com/cover.jpg',
        },
      ],
      'lectoras': [
        {
          'id': 'user-1',
          'nombre': 'Cristina',
          'total': 1,
          'avatarUrl': 'https://example.com/avatar.jpg',
        },
      ],
    });

    expect(data.libros.single.id, 'book-1');
    expect(data.libros.single.coverUrl, contains('cover.jpg'));
    expect(data.lectoras.single.id, 'user-1');
    expect(data.lectoras.single.avatarUrl, contains('avatar.jpg'));
  });

  test('mantiene compatibilidad con la respuesta antigua', () {
    final item = TendenciaItem.fromJson({'nombre': 'Fantasía', 'total': 2});

    expect(item.id, isEmpty);
    expect(item.coverUrl, isEmpty);
    expect(item.avatarUrl, isEmpty);
  });
}
