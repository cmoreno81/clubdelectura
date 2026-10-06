import 'dart:convert';

import 'package:club_lectura_app/services/wishlist_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Client _servidor() => MockClient((request) async {
  final item = {
    'id': 'i1',
    'title': 'Yesteryear',
    'format': 'PHYSICAL',
    'priority': 'MEDIUM',
    'createdAt': '2026-10-05T10:00:00Z',
    'updatedAt': '2026-10-05T10:00:00Z',
  };
  if (request.method == 'DELETE' && request.url.path.endsWith('/purchased')) {
    return http.Response(jsonEncode({'ok': true, 'item': item}), 200);
  }
  if (request.method == 'DELETE') {
    return http.Response(jsonEncode({'ok': true}), 200);
  }
  return http.Response(jsonEncode({'ok': true, 'item': item}), 200);
});

void main() {
  // Las tarjetas del inicio se recargan con este aviso: si no salta, siguen
  // enseñando libros que ya no están en la lista.
  test('cada cambio en la lista de deseos avisa a las tarjetas del inicio', () async {
    final service = WishlistService(client: _servidor());
    final antes = WishlistService.cambios.value;

    await service.addItem(title: 'Yesteryear');
    expect(WishlistService.cambios.value, antes + 1);

    await service.markPurchased('i1');
    expect(WishlistService.cambios.value, antes + 2);

    await service.unmarkPurchased('i1');
    expect(WishlistService.cambios.value, antes + 3);

    await service.deleteItem('i1');
    expect(WishlistService.cambios.value, antes + 4);
  });

  test('un cambio que falla no avisa', () async {
    final service = WishlistService(
      client: MockClient(
        (_) async => http.Response(jsonEncode({'mensaje': 'No existe'}), 404),
      ),
    );
    final antes = WishlistService.cambios.value;
    await expectLater(service.deleteItem('nope'), throwsA(anything));
    expect(WishlistService.cambios.value, antes);
  });
}
