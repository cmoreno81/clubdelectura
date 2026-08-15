import 'dart:convert';

import 'package:club_lectura_app/models/notificacion.dart';
import 'package:club_lectura_app/models/club_membership.dart';
import 'package:club_lectura_app/pages/home_page.dart';
import 'package:club_lectura_app/services/api_exception.dart';
import 'package:club_lectura_app/services/api_service.dart';
import 'package:club_lectura_app/services/notificaciones_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('clasifica Lecturas, Clubvisión y actividad general del club', () {
    expect(
      notificationBadgeCategory('LECTURA_NUEVA'),
      NotificationBadgeCategory.lecturas,
    );
    expect(
      notificationBadgeCategory('COMENTARIO_LECTURA'),
      NotificationBadgeCategory.lecturas,
    );
    expect(
      notificationBadgeCategory('CLUBVISION_ABIERTA'),
      NotificationBadgeCategory.clubvision,
    );
    expect(
      notificationBadgeCategory('CLUBVISION_RESULTADOS'),
      NotificationBadgeCategory.clubvision,
    );
    expect(
      notificationBadgeCategory('CLUB_BOOK_OF_YEAR'),
      NotificationBadgeCategory.club,
    );
  });

  test(
    'leer y eliminar actualizan la categoría sin valores negativos',
    () async {
      final service = _service();
      await service.cargar();
      expect(service.noLeidasLecturas, 2);

      await service.marcarLeida('l1', tipo: 'LECTURA_NUEVA');
      await service.marcarLeida('l1', tipo: 'LECTURA_NUEVA');
      expect(service.noLeidasLecturas, 1);

      await service.eliminar(_notification('l2', 'COMENTARIO_LECTURA'));
      expect(service.noLeidasLecturas, 0);
      expect(service.noLeidas, 2);

      await service.eliminar(
        _notification('read', 'LECTURA_NUEVA', leida: true),
      );
      expect(service.noLeidasLecturas, 0);
    },
  );

  test('marcar todas y eliminar todas dejan todos los badges a cero', () async {
    final service = _service(emptyAfterMutation: true);
    await service.cargar();
    await service.marcarTodas();
    expect(service.noLeidas, 0);
    expect(service.noLeidasClub, 0);
    expect(service.noLeidasLecturas, 0);
    expect(service.noLeidasClubvision, 0);

    await service.eliminarTodas();
    expect(service.noLeidas, 0);
  });

  test('un fallo de backend conserva los contadores anteriores', () async {
    final service = _service(failMutations: true);
    await service.cargar();
    await expectLater(service.marcarTodas(), throwsA(isA<ApiException>()));
    expect(service.noLeidas, 4);
    expect(service.noLeidasLecturas, 2);
  });

  testWidgets(
    'HomePage oculta inmediatamente el badge de Lecturas sin cambiar de pestaña',
    (tester) async {
      final service = _service(emptyAfterMutation: true);
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            club: const ClubMembership(
              id: 'club-1',
              nombre: 'Club',
              slug: 'club',
              rol: 'MEMBER',
              activo: true,
            ),
            notificationService: service,
            pageBuilders: List.generate(
              5,
              (index) =>
                  () => Text('Página $index'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_badgeFor(tester, 'Lecturas').isLabelVisible, isTrue);
      expect(find.text('Página 0'), findsOneWidget);

      await service.marcarTodas();
      await tester.pump();

      expect(_badgeFor(tester, 'Lecturas').isLabelVisible, isFalse);
      expect(_badgeFor(tester, 'El Club').isLabelVisible, isFalse);
      expect(find.text('Página 0'), findsOneWidget);
      expect(find.text('Página 3'), findsNothing);
    },
  );

  testWidgets('el modo individual no solicita contadores sociales', (
    tester,
  ) async {
    var requests = 0;
    final service = NotificacionesService.testing(
      ApiService(
        client: MockClient((_) async {
          requests++;
          return http.Response('{}', 200);
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          club: const ClubMembership(
            id: 'personal',
            nombre: 'Mi espacio',
            slug: 'personal',
            rol: 'OWNER',
            activo: true,
            tipo: TipoClub.personal,
          ),
          notificationService: service,
          pageBuilders: List.generate(
            4,
            (index) =>
                () => Text('Personal $index'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(find.text('Lecturas'), findsNothing);
    expect(find.text('Clubvisión'), findsNothing);
  });
}

Badge _badgeFor(WidgetTester tester, String label) {
  final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
  final destination = navigation.destinations
      .cast<NavigationDestination>()
      .firstWhere((item) => item.label == label);
  return destination.icon as Badge;
}

NotificacionesService _service({
  bool failMutations = false,
  bool emptyAfterMutation = false,
}) {
  var mutated = false;
  final client = MockClient((request) async {
    final action = request.url.queryParameters['action'];
    if (action == 'notificaciones') {
      final items = mutated && emptyAfterMutation
          ? const <Map<String, dynamic>>[]
          : [
              _json('l1', 'LECTURA_NUEVA'),
              _json('l2', 'COMENTARIO_LECTURA'),
              _json('cv', 'CLUBVISION_ABIERTA'),
              _json('club', 'CLUB_BOOK_OF_YEAR'),
            ];
      return http.Response(
        jsonEncode({
          'ok': true,
          'noLeidas': items.length,
          'notificaciones': items,
        }),
        200,
      );
    }
    if (failMutations) {
      return http.Response(jsonEncode({'ok': false, 'mensaje': 'Error'}), 500);
    }
    mutated = true;
    return http.Response(jsonEncode({'ok': true}), 200);
  });
  return NotificacionesService.testing(ApiService(client: client));
}

Map<String, dynamic> _json(String id, String type) => {
  'id': id,
  'tipo': type,
  'titulo': 'Título',
  'mensaje': 'Mensaje',
  'leida': false,
  'fecha': '2026-08-15',
};

Notificacion _notification(String id, String type, {bool leida = false}) =>
    Notificacion(
      id: id,
      tipo: type,
      titulo: 'Título',
      mensaje: 'Mensaje',
      leida: leida,
      fecha: '2026-08-15',
    );
