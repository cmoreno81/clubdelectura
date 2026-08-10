import 'dart:convert';

import 'package:club_lectura_app/services/api_service.dart';
import 'package:club_lectura_app/services/authenticated_http_client.dart';
import 'package:club_lectura_app/services/club_dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('una carga usa solo dashboard y consume su top y Clubvisión', () async {
    final actions = <String>[];
    final client = MockClient((request) async {
      actions.add(request.url.queryParameters['action'] ?? '');
      expect(request.headers[AuthenticatedHttpClient.noRetryHeader], 'true');
      return http.Response(
        jsonEncode({
          'usuarioActual': {
            'nombre': 'Cristina',
            'avatarUrl': 'https://example.test/cristina.jpg',
          },
          'resumen': {'usuarioMes': 'Ada', 'librosUsuarioMes': 4},
          'clubvision': {'estado': 'VOTACION', 'haVotado': true},
          'topLectorasMes': [
            {
              'usuario': 'Ada',
              'avatarUrl': 'https://example.test/ada.jpg',
              'total': 4,
            },
            {
              'usuario': 'Bea',
              'avatarUrl': 'https://example.test/bea.jpg',
              'total': 3,
            },
            {
              'usuario': 'Celia',
              'avatarUrl': 'https://example.test/celia.jpg',
              'total': 2,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = ClubDashboardService(api: ApiService(client: client));

    final result = await service.load();

    expect(actions, ['dashboard']);
    expect(actions, isNot(contains('usuarios')));
    expect(actions, isNot(contains('perfilUsuario')));
    expect(actions, isNot(contains('clubvision')));
    expect(result.topLectoras?.map((item) => item.nombre), [
      'Ada',
      'Bea',
      'Celia',
    ]);
    expect(result.topLectoras?.map((item) => item.total), [4, 3, 2]);
    expect(result.haVotado, isTrue);
    expect(result.dashboard.usuarioActual, 'Cristina');
    expect(
      result.dashboard.avatarUrlActual,
      'https://example.test/cristina.jpg',
    );
  });
}
