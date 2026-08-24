import 'dart:convert';

import 'package:club_lectura_app/models/upcoming_release.dart';
import 'package:club_lectura_app/services/upcoming_releases_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parses editorial cliches from a release', () {
    final release = UpcomingRelease.fromJson({
      'bookId': 'book-1',
      'title': 'Libro',
      'publicationDate': '2026-09-01T12:00:00.000Z',
      'genre': 'Romance',
      'cliches': ['Enemies to Lovers', 'Slow Burn'],
    });

    expect(release.cliches, ['Enemies to Lovers', 'Slow Burn']);
  });

  test('interpreta de forma independiente wishlist y biblioteca', () {
    final release = UpcomingRelease.fromJson({
      'id': 17,
      'titulo': 'Una novedad',
      'autor': 'Autora',
      'publicationDate': '2099-09-14T00:00:00.000Z',
      'isInWishlist': true,
      'isInLibrary': false,
      'wishlistItemId': 31,
    });

    expect(release.isInWishlist, isTrue);
    expect(release.isInLibrary, isFalse);
    expect(release.wishlistItemId, '31');
    expect(release.title, 'Una novedad');
    expect(release.author, 'Autora');
  });

  test('acepta la respuesta en español de próximos lanzamientos', () async {
    final service = UpcomingReleasesService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/books/upcoming');
        return http.Response(
          jsonEncode({
            'libros': [
              {
                'id': 'release-1',
                'titulo': 'La novedad esperada',
                'autor': 'Autora',
                'fechaLanzamiento': '2099-10-20',
                'genero': 'Fantasía',
                'editorial': 'Editorial',
                'fuente': 'Casa del Libro',
              },
            ],
          }),
          200,
        );
      }),
    );

    final releases = await service.load(limit: 6);

    expect(releases, hasLength(1));
    expect(releases.single.title, 'La novedad esperada');
    expect(releases.single.source, 'Casa del Libro');
  });
}
