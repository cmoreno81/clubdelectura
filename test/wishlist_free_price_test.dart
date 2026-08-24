import 'package:club_lectura_app/models/wishlist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('distingue un libro gratis de otro sin precio conocido', () {
    WishlistItem itemWithPrice(dynamic price) => WishlistItem.fromJson({
      'id': 'item',
      'title': 'Ebook',
      'format': 'DIGITAL',
      'priority': 'MEDIUM',
      'price': price,
      'createdAt': '2026-08-24T10:00:00Z',
      'updatedAt': '2026-08-24T10:00:00Z',
    });

    expect(itemWithPrice(0).isFree, isTrue);
    expect(itemWithPrice(null).isFree, isFalse);
    expect(itemWithPrice(9.99).isFree, isFalse);
  });
}
