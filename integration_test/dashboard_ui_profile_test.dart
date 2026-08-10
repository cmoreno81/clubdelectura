import 'dart:io';
import 'dart:ui';

import 'package:club_lectura_app/models/dashboard.dart';
import 'package:club_lectura_app/models/dashboard_view_data.dart';
import 'package:club_lectura_app/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard long-scroll profile', (tester) async {
    final timings = <FrameTiming>[];
    void collectTimings(List<FrameTiming> values) => timings.addAll(values);
    WidgetsBinding.instance.addTimingsCallback(collectTimings);
    addTearDown(
      () => WidgetsBinding.instance.removeTimingsCallback(collectTimings),
    );
    final rssBefore = ProcessInfo.currentRss;
    var requests = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(
          clubName: 'ClubReads profile',
          loadData: () async {
            requests++;
            return _dashboardFixture();
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    for (var index = 0; index < 12; index++) {
      await tester.fling(
        find.byType(Scrollable).first,
        Offset(0, index.isEven ? -700 : 700),
        2200,
      );
      await tester.pump(const Duration(milliseconds: 250));
    }

    final rssAfter = ProcessInfo.currentRss;
    final buildMicros = timings
        .map((frame) => frame.buildDuration.inMicroseconds)
        .toList(growable: false);
    final slowFrames = timings
        .where((frame) => frame.totalSpan > const Duration(milliseconds: 16))
        .length;
    final worstBuildMicros = buildMicros.isEmpty
        ? 0
        : buildMicros.reduce((a, b) => a > b ? a : b);
    // ignore: avoid_print
    print(
      'DASHBOARD_UI_PROFILE requests=$requests frames=${timings.length} '
      'slowFrames=$slowFrames worstBuildUs=$worstBuildMicros '
      'rssBefore=$rssBefore rssAfter=$rssAfter '
      'rssDelta=${rssAfter - rssBefore}',
    );
    expect(requests, 1);
    expect(tester.takeException(), isNull);
  });
}

DashboardViewData _dashboardFixture() => DashboardViewData(
  dashboard: Dashboard.fromJson({
    'usuarioActual': {'nombre': 'Usuaria 0', 'avatarUrl': ''},
    'leyendoAhora': [
      for (var member = 0; member < 16; member++)
        {
          'usuario': 'Usuaria $member',
          'avatarUrl': '',
          'total': 3,
          'lecturas': [
            for (var book = 0; book < 3; book++)
              {
                'libraryId': '$member-$book',
                'bookId': 'book-$member-$book',
                'titulo': 'Libro $book de usuaria $member',
                'coverUrl': '',
                'progreso': 35 + book * 10,
                'comentario': 'Impresión de lectura',
                'reacciones': const {},
              },
          ],
        },
    ],
  }),
  haVotado: false,
  topLectoras: const [],
);
