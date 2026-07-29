import 'dart:convert';

import 'package:club_lectura_app/models/general_dashboard.dart';
import 'package:club_lectura_app/services/general_dashboard_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('el dashboard antiguo sin estantería anual sigue siendo válido', () {
    final dashboard = GeneralDashboard.fromJson(const {});

    expect(dashboard.yearShelf, isEmpty);
  });

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
            'miBiblioteca': [
              {
                'id': 'book-2',
                'titulo': 'Próxima lectura',
                'genero': 'Fantasía',
                'coverUrl': '',
                'prioridad': 'ALTA',
                'estado': 'PENDIENTE',
                'formato': 'DIGITAL',
              },
            ],
            'sagasAbiertas': [
              {
                'id': 'saga-1',
                'nombre': 'Windy City',
                'leidos': 2,
                'total': 5,
                'coverUrl': 'https://example.com/series.jpg',
                'siguiente': {
                  'id': 'book-3',
                  'titulo': 'Siguiente libro',
                  'coverUrl': '',
                  'enMiBiblioteca': true,
                },
              },
            ],
            'estanteriaAnual': [
              {
                'id': 'completion-year-1',
                'bookId': 'book-year-1',
                'titulo': 'Lectura de 2026',
                'coverUrl': 'https://example.com/year.jpg',
                'fechaFin': '2026-05-12T10:00:00.000Z',
              },
            ],
            'calendario': {
              'anio': 2026,
              'mes': 7,
              'librosLeidos': [
                {
                  'id': 'completion-1:book-4',
                  'bookId': 'book-4',
                  'titulo': 'Libro terminado',
                  'coverUrl': 'https://example.com/cover.jpg',
                  'fechaFin': '2026-07-20T10:00:00.000Z',
                  'paginas': 384,
                },
              ],
              'lecturasCalendario': [
                {
                  'id': 'completion:completion-1',
                  'bookId': 'book-4',
                  'titulo': 'Libro terminado',
                  'coverUrl': 'https://example.com/cover.jpg',
                  'fechaInicio': '2026-07-15T10:00:00.000Z',
                  'fechaFin': '2026-07-20T10:00:00.000Z',
                },
              ],
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
            'comunidad': {
              'clubes': 2,
              'lectoras': 10,
              'lecturasActivas': 5,
              'formatos': {
                'fisico': 6,
                'digital': 3,
                'audiolibro': 1,
                'total': 10,
              },
            },
          }),
          200,
        );
      }),
    );

    final dashboard = await service.load();

    expect(dashboard.userName, 'Cristina');
    expect(dashboard.summary.monthStreak, 3);
    expect(dashboard.clubs.single.name, 'Nuestros gustos son clichés');
    expect(dashboard.personalLibrary.single.title, 'Próxima lectura');
    expect(dashboard.personalLibrary.single.isHighPriority, isTrue);
    expect(dashboard.personalLibrary.single.format, 'DIGITAL');
    expect(dashboard.openSeries.single.read, 2);
    expect(dashboard.openSeries.single.total, 5);
    expect(
      dashboard.openSeries.single.coverUrl,
      'https://example.com/series.jpg',
    );
    expect(dashboard.openSeries.single.next?.title, 'Siguiente libro');
    expect(dashboard.yearShelf.single.title, 'Lectura de 2026');
    expect(dashboard.calendar.events.single.day, 28);
    expect(dashboard.calendar.finishedBooks.single.title, 'Libro terminado');
    expect(dashboard.calendar.finishedBooks.single.pages, 384);
    expect(dashboard.calendar.readings.single.startedAt, contains('07-15'));
    expect(dashboard.trending.single.readers, 4);
    expect(dashboard.community.formats.physical, 6);
    expect(dashboard.community.formats.audiobook, 1);
    expect(dashboard.community.formats.total, 10);
  });
}
