import 'dart:convert';

import 'package:club_lectura_app/services/general_dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('interpreta el dashboard personal y multiclub', () async {
    final service = GeneralDashboardService(
      client: MockClient((request) async {
        expect(request.url.queryParameters['action'], 'dashboardGeneral');
        return http.Response(
          jsonEncode({
            'ok': true,
            'usuario': {'nombre': 'Cristina', 'avatarUrl': ''},
            'resumen': {
              'clubes': 1,
              'leyendo': 2,
              'terminados': 14,
              'terminadosMes': 1,
              'paginasLeidas': 4200,
              'rachaMeses': 3,
            },
            'clubes': [
              {
                'id': 'club-1',
                'nombre': 'Nuestros gustos son clichés',
                'rol': 'OWNER',
                'activo': true,
                'miembros': 9,
                'lecturasActivas': 2,
              },
            ],
            'leyendoAhora': [
              {
                'id': 'book-1',
                'titulo': 'Libro',
                'genero': 'Ficción',
                'coverUrl': '',
                'progreso': 40,
              },
            ],
            'calendario': {
              'anio': 2026,
              'mes': 7,
              'eventos': [
                {
                  'fecha': '2026-07-28',
                  'dia': 28,
                  'tipos': ['PROGRESO'],
                  'libros': ['Libro'],
                },
              ],
            },
            'tendencias': [
              {
                'id': 'book-1',
                'titulo': 'Libro',
                'coverUrl': '',
                'lectoras': 4,
              },
            ],
            'comunidad': {'clubes': 2, 'lectoras': 10, 'lecturasActivas': 5},
          }),
          200,
        );
      }),
    );

    final dashboard = await service.load();

    expect(dashboard.userName, 'Cristina');
    expect(dashboard.summary.monthStreak, 3);
    expect(dashboard.clubs.single.name, 'Nuestros gustos son clichés');
    expect(dashboard.calendar.events.single.day, 28);
    expect(dashboard.trending.single.readers, 4);
  });
}
