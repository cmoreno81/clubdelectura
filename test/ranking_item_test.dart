import 'package:club_lectura_app/models/ranking_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el ranking conserva la portada y la identidad del libro', () {
    final item = RankingItem.fromJson({
      'libro': 'Book lovers',
      'bookId': 'book-1',
      'coverUrl': 'https://example.com/book-lovers.jpg',
      'media': 5,
      'votos': 2,
    });

    expect(item.nombre, 'Book lovers');
    expect(item.bookId, 'book-1');
    expect(item.coverUrl, 'https://example.com/book-lovers.jpg');
    expect(item.media, 5);
  });
}
