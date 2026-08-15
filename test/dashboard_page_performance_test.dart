import 'dart:async';

import 'package:club_lectura_app/models/auth_session.dart';
import 'package:club_lectura_app/models/dashboard.dart';
import 'package:club_lectura_app/models/dashboard_view_data.dart';
import 'package:club_lectura_app/pages/dashboard_page.dart';
import 'package:club_lectura_app/widgets/dashboard/club_books_of_year_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la cabecera usa la sesión antes de visitar el perfil', (
    tester,
  ) async {
    final pending = Completer<DashboardViewData>();
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(
          clubName: 'ClubReads',
          initialUser: const AuthUser(
            id: 'user-1',
            nombre: 'Ada Lovelace',
            email: 'ada@example.test',
            avatarUrl: 'https://example.invalid/ada.jpg',
          ),
          loadData: () => pending.future,
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('?'), findsNothing);
    pending.complete(_viewData());
    await tester.pump();
  });

  testWidgets('abrir el perfil lo construye una vez y no recrea el dashboard', (
    tester,
  ) async {
    var dashboardRequests = 0;
    var profileBuilds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(
          clubName: 'ClubReads',
          initialUser: const AuthUser(
            id: 'user-1',
            nombre: 'Ada Lovelace',
            email: 'ada@example.test',
          ),
          loadData: () async {
            dashboardRequests++;
            return _viewData();
          },
          profilePageBuilder: (_) {
            profileBuilds++;
            return const Scaffold(body: Text('perfil cargado'));
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('AL'));
    await tester.pumpAndSettle();
    expect(find.text('perfil cargado'), findsOneWidget);
    expect(profileBuilds, 1);
    expect(dashboardRequests, 1);
  });

  testWidgets('rebuild conserva el Future y no inicia otra petición', (
    tester,
  ) async {
    var requests = 0;
    final key = GlobalKey();

    Future<DashboardViewData> load() async {
      requests++;
      return DashboardViewData(
        dashboard: Dashboard.fromJson(const {}),
        haVotado: false,
        topLectoras: const [],
      );
    }

    Widget app(String clubName) => MaterialApp(
      home: DashboardPage(key: key, clubName: clubName, loadData: load),
    );

    await tester.pumpWidget(app('ClubReads'));
    await tester.pump();
    await tester.pumpWidget(app('ClubReads'));
    await tester.pump();

    expect(requests, 1);
  });

  testWidgets('el controlador refresca una vez y conserva la página', (
    tester,
  ) async {
    var requests = 0;
    final controller = DashboardPageController();

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(
          clubName: 'ClubReads',
          controller: controller,
          loadData: () async {
            requests++;
            return DashboardViewData(
              dashboard: Dashboard.fromJson(const {}),
              haVotado: false,
              topLectoras: const [],
            );
          },
        ),
      ),
    );
    await tester.pump();
    final stateBefore = tester.state(find.byType(DashboardPage));

    await controller.refresh();
    await tester.pump();

    expect(requests, 2);
    expect(tester.state(find.byType(DashboardPage)), same(stateBefore));
  });

  testWidgets(
    'el modo individual no construye ni reserva espacio para el año del club',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardPage(
            clubName: 'Mi espacio',
            esPersonal: true,
            loadData: () async => _viewData(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClubBooksOfYearCard), findsNothing);
      expect(find.text('El año del club'), findsNothing);
      expect(find.text('Libro del año del club'), findsNothing);
      expect(find.text('Elecciones de los miembros'), findsNothing);
    },
  );
}

DashboardViewData _viewData() => DashboardViewData(
  dashboard: Dashboard.fromJson(const {}),
  haVotado: false,
  topLectoras: const [],
);
