import 'dart:convert';

import 'package:club_lectura_app/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'las acciones paginadas envían limit y cursor y leen metadatos',
    () async {
      final actions = <String>[];
      final client = MockClient((request) async {
        actions.add(request.url.queryParameters['action']!);
        expect(request.method, 'GET');
        expect(request.url.queryParameters['limit'], '12');
        expect(request.url.queryParameters['cursor'], 'cursor-opaco');
        return switch (request.url.queryParameters['action']) {
          'notificaciones' => http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 'n1',
                  'tipo': 'LECTURA_NUEVA',
                  'titulo': 'Título',
                  'mensaje': 'Mensaje',
                  'leida': false,
                  'fecha': '2026-08-09T10:00:00.000Z',
                },
              ],
              'nextCursor': 'siguiente',
              'hasMore': true,
            }),
            200,
          ),
          'catalogoGeneral' => http.Response(
            jsonEncode({
              'items': [
                {
                  'id': 'b1',
                  'origen': 'CLUBREADS',
                  'titulo': 'Libro',
                  'autores': ['Autora'],
                },
              ],
              'nextCursor': null,
              'hasMore': false,
            }),
            200,
          ),
          'comentariosLectura' => http.Response(
            jsonEncode({
              'items': [
                {'id': 'c1', 'usuario': 'Lectora', 'comentario': 'Texto'},
              ],
              'nextCursor': null,
              'hasMore': false,
            }),
            200,
          ),
          'historialClubvision' => http.Response(
            jsonEncode({
              'items': [
                {'mes': '2026-08', 'ganadora': 'Libro', 'puntos': 12},
              ],
              'nextCursor': null,
              'hasMore': false,
            }),
            200,
          ),
          'conversacionesLibro' => http.Response(
            jsonEncode({
              'items': [
                {
                  'libro': 'Libro',
                  'tipo': 'OFICIAL',
                  'estado': 'ACTIVA',
                  'comentarios': 2,
                  'likes': 1,
                  'ultimaActividad': '2026-08-09T10:00:00.000Z',
                },
              ],
              'nextCursor': null,
              'hasMore': false,
            }),
            200,
          ),
          'librosFinalizados' => http.Response(
            jsonEncode({
              'items': [
                {
                  'libro': 'Libro terminado',
                  'usuario': 'Lectora',
                  'fechaFin': '2026-08-09',
                },
              ],
              'nextCursor': null,
              'hasMore': false,
            }),
            200,
          ),
          _ => http.Response('{}', 404),
        };
      });
      final api = ApiService(client: client);

      final notifications = await api.getNotificacionesPage(
        limit: 12,
        cursor: 'cursor-opaco',
      );
      final catalog = await api.getCatalogoGeneralPage(
        limit: 12,
        cursor: 'cursor-opaco',
      );
      final comments = await api.getComentariosCapituloPage(
        libro: 'Libro',
        capitulo: '1',
        limit: 12,
        cursor: 'cursor-opaco',
      );
      final history = await api.getHistorialClubvisionPage(
        limit: 12,
        cursor: 'cursor-opaco',
      );
      final conversations = await api.getConversacionesLibroPage(
        libro: 'Libro',
        limit: 12,
        cursor: 'cursor-opaco',
      );
      final finished = await api.getLibrosFinalizadosPage(
        limit: 12,
        cursor: 'cursor-opaco',
      );

      expect(actions, [
        'notificaciones',
        'catalogoGeneral',
        'comentariosLectura',
        'historialClubvision',
        'conversacionesLibro',
        'librosFinalizados',
      ]);
      expect(notifications.items.single.id, 'n1');
      expect(notifications.nextCursor, 'siguiente');
      expect(notifications.hasMore, isTrue);
      expect(catalog.items.single.id, 'b1');
      expect(comments.items.single.id, 'c1');
      expect(history.items.single.mes, '2026-08');
      expect(conversations.items.single.tipo, 'OFICIAL');
      expect(finished.items.single.libro, 'Libro terminado');
    },
  );
}
