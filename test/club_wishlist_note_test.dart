import 'package:club_lectura_app/models/wishlist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conserva el comentario de cada miembro de la wishlist del club', () {
    final data = ClubWishlistData.fromJson({
      'clubName': 'Club de prueba',
      'items': [
        {
          'key': 'book-1',
          'title': 'Una novedad',
          'members': [
            {
              'userId': 'user-1',
              'name': 'Cristina Moreno',
              'format': 'PHYSICAL',
              'comentario': 'Me interesa especialmente esta edición.',
            },
            {
              'userId': 'user-2',
              'name': 'Otra lectora',
              'format': 'DIGITAL',
              'note': '   ',
            },
          ],
        },
      ],
      'totalItems': 1,
      'totalMembers': 2,
      'membersWithWishlist': 2,
    });

    expect(
      data.items.single.members.first.note,
      'Me interesa especialmente esta edición.',
    );
    expect(data.items.single.members.last.note, isNull);
  });
}
