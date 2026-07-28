import 'dart:convert';

import 'package:club_lectura_app/services/club_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('carga las membresías y el club activo', () async {
    final service = ClubService(
      client: MockClient((request) async {
        expect(request.url.queryParameters['action'], 'misClubes');
        return http.Response(
          jsonEncode({
            'ok': true,
            'activeClubId': 'club-1',
            'clubs': [
              {
                'id': 'club-1',
                'nombre': 'Lecturas',
                'slug': 'lecturas',
                'rol': 'OWNER',
                'activo': true,
              },
            ],
          }),
          200,
        );
      }),
    );

    final result = await service.getMyClubs();

    expect(result.activeClubId, 'club-1');
    expect(result.clubs.single.nombre, 'Lecturas');
    expect(result.clubs.single.activo, isTrue);
  });

  test(
    'crear, unirse y seleccionar usan contratos autenticados sin usuario',
    () async {
      final actions = <String>[];
      final service = ClubService(
        client: MockClient((request) async {
          actions.add(request.url.queryParameters['action']!);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body.containsKey('usuario'), isFalse);
          return http.Response(jsonEncode({'ok': true}), 200);
        }),
      );

      await service.createClub(nombre: 'Nuevo club');
      await service.joinClub('ABC123');
      await service.selectClub('club-2');

      expect(actions, ['crearClub', 'unirseClub', 'seleccionarClub']);
    },
  );
}
