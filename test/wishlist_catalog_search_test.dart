import 'dart:convert';

import 'package:club_lectura_app/services/wishlist_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('prioriza ClubReads y conserva también resultados de Google', () async {
    final service = WishlistService(
      client: MockClient((request) async {
        expect(request.url.queryParameters['action'], 'buscarCatalogoGeneral');
        expect(request.url.queryParameters['q'], 'La asistenta');
        return http.Response(
          jsonEncode({
            'libros': [
              {
                'id': 'clubreads-1',
                'origen': 'CLUBREADS',
                'titulo': 'La asistenta',
                'autores': ['Freida McFadden'],
                'coverUrl': 'https://example.com/cover.jpg',
                'isbn': '9780000000001',
                'fechaPublicacion': '2022-04-26',
              },
              {
                'id': 'google-1',
                'origen': 'GOOGLE',
                'titulo': 'Resultado externo',
              },
            ],
          }),
          200,
        );
      }),
    );

    final results = await service.searchBooks('  La asistenta  ');

    expect(results, hasLength(2));
    expect(results.first.bookId, 'clubreads-1');
    expect(results.first.title, 'La asistenta');
    expect(results.first.author, 'Freida McFadden');
    expect(results.first.publishedDate, '2022-04-26');
    expect(results.first.sourceLabel, 'En ClubReads');
    expect(results.last.bookId, isNull);
    expect(results.last.sourceLabel, 'Google Books');
  });
}
