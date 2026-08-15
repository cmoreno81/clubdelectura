import 'dart:io';

import 'package:club_lectura_app/models/dashboard.dart';
import 'package:club_lectura_app/models/dashboard_view_data.dart';
import 'package:club_lectura_app/pages/dashboard_page.dart';
import 'package:club_lectura_app/services/api_service.dart';
import 'package:club_lectura_app/widgets/common/checkin_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'abrir, reconstruir y refrescar el dashboard solo consulta historial',
    (tester) async {
      var dashboardLoads = 0;
      var historyReads = 0;
      final controller = DashboardPageController();

      Widget app() => MaterialApp(
        home: DashboardPage(
          clubName: 'ClubReads',
          controller: controller,
          loadData: () async {
            dashboardLoads++;
            return _viewData();
          },
          loadCheckinHistory: () async {
            historyReads++;
            return {'streak': 4, 'checkedToday': false};
          },
        ),
      );

      await tester.pumpWidget(app());
      await tester.pump();
      expect(historyReads, 1);
      expect(find.text('Marca que has leído hoy'), findsOneWidget);

      await tester.pumpWidget(app());
      await tester.pump();
      expect(historyReads, 1);

      await controller.refresh();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(historyReads, 2);
      expect(dashboardLoads, greaterThanOrEqualTo(2));

      final dashboardSource = File(
        'lib/pages/dashboard_page.dart',
      ).readAsStringSync();
      expect(dashboardSource, isNot(contains('registrarVisita')));
      expect(dashboardSource, isNot(contains('doCheckin(')));
      expect(dashboardSource, contains('onRefresh: _recargar'));
    },
  );

  test('consultar historial usa GET y no crea actividad', () async {
    var requests = 0;
    final api = ApiService(
      client: MockClient((request) async {
        requests++;
        expect(request.method, 'GET');
        expect(request.url.queryParameters['action'], 'historialCheckin');
        expect(request.url.queryParameters['dias'], '7');
        return http.Response('{"streak":3,"checkedToday":false}', 200);
      }),
    );

    final result = await api.getHistorialCheckin(dias: 7);
    expect(result['streak'], 3);
    expect(requests, 1);
  });

  testWidgets('el check-in explícito crea el registro y actualiza la racha', (
    tester,
  ) async {
    var writes = 0;
    var reportedStreak = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckinButton(
            checkedToday: false,
            streak: 2,
            doCheckin: () async {
              writes++;
              return {'ok': true, 'checkedToday': true, 'streak': 3};
            },
            onCheckinDone: (value) => reportedStreak = value,
          ),
        ),
      ),
    );

    expect(writes, 0);
    await tester.tap(find.text('¡Sí!'));
    await tester.pump();
    expect(writes, 1);
    expect(reportedStreak, 3);
    expect(find.text('Llevas 3 días de racha'), findsOneWidget);
  });

  testWidgets('club, Perfil y Mi espacio representan la misma racha oficial', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              RachaLectoraCard(
                loadHistory: () async => {'streak': 6, 'checkedToday': true},
              ),
              const CheckinButton(checkedToday: true, streak: 6),
              const CheckinButton(checkedToday: true, streak: 6),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('6'), findsOneWidget);
    expect(find.text('Llevas 6 días de racha'), findsNWidgets(2));
  });

  test('no queda una racha local compartida entre usuarias', () {
    expect(
      File('lib/services/reading_streak_service.dart').existsSync(),
      isFalse,
    );
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final source = dartFiles.map((file) => file.readAsStringSync()).join('\n');
    expect(source, isNot(contains('streak_count')));
    expect(source, isNot(contains('streak_last_date')));
    expect(source, isNot(contains('registrarVisita')));
  });
}

DashboardViewData _viewData() => DashboardViewData(
  dashboard: Dashboard.fromJson(const {}),
  haVotado: false,
  topLectoras: const [],
);
