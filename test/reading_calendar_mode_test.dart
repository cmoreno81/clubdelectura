import 'package:club_lectura_app/models/general_dashboard.dart';
import 'package:club_lectura_app/services/reading_calendar_mode_service.dart';
import 'package:club_lectura_app/widgets/common/calendar_mode_toggle.dart';
import 'package:club_lectura_app/widgets/common/reading_cover_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReadingCalendar _calendario() => ReadingCalendar(
  year: 2026,
  month: 9,
  events: const [],
  readings: const [
    // Terminado el 5, leído del 3 al 5.
    MonthlyReadingSpan(
      id: 'completion:c1',
      libraryId: 'l1',
      bookId: 'b1',
      title: 'Terminado',
      coverUrl: '',
      startedAt: '2026-09-03T12:00:00.000Z',
      finishedAt: '2026-09-05T12:00:00.000Z',
    ),
    // En curso: se pinta hasta «hoy» (día 9) pero aún no se ha terminado.
    MonthlyReadingSpan(
      id: 'library:l2',
      libraryId: 'l2',
      bookId: 'b2',
      title: 'EnCurso',
      coverUrl: '',
      startedAt: '2026-09-08T12:00:00.000Z',
      finishedAt: '2026-09-09T12:00:00.000Z',
    ),
  ],
  finishedBooks: const [
    MonthlyFinishedBook(
      id: 'c1:b1',
      bookId: 'b1',
      title: 'Terminado',
      coverUrl: '',
      finishedAt: '2026-09-05T12:00:00.000Z',
      pages: 300,
      rating: 4,
    ),
  ],
);

Finder _dia(int dia, String titulo) =>
    find.bySemanticsLabel(RegExp('^Día $dia, $titulo'));

Widget _app(Widget hijo) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: hijo)),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReadingCalendarModeService.reiniciar();
  });

  testWidgets('por defecto la portada sale todos los días de la lectura', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(ReadingCoverCalendar(calendar: _calendario())),
    );
    await tester.pump();

    for (final dia in [3, 4, 5]) {
      expect(_dia(dia, 'Terminado'), findsOneWidget);
    }
    expect(_dia(9, 'EnCurso'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('«Al terminar» solo la pone el día que se terminó', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(ReadingCoverCalendar(calendar: _calendario(), soloDiaDeFin: true)),
    );
    await tester.pump();

    expect(_dia(5, 'Terminado'), findsOneWidget);
    expect(_dia(3, 'Terminado'), findsNothing);
    expect(_dia(4, 'Terminado'), findsNothing);
    // Un libro sin terminar no aparece en ningún día.
    expect(_dia(9, 'EnCurso'), findsNothing);
    semantics.dispose();
  });

  testWidgets('el interruptor cambia el calendario y se recuerda', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            const CalendarModeToggle(),
            ReadingCoverCalendar(calendar: _calendario()),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(_dia(4, 'Terminado'), findsOneWidget);

    await tester.tap(find.text('Al terminar'));
    await tester.pump();
    expect(_dia(4, 'Terminado'), findsNothing);
    expect(_dia(5, 'Terminado'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reading_calendar_solo_dia_fin'), isTrue);

    await tester.tap(find.text('Cada día'));
    await tester.pump();
    expect(_dia(4, 'Terminado'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('recupera el modo guardado al abrir la app', (tester) async {
    SharedPreferences.setMockInitialValues({
      'reading_calendar_solo_dia_fin': true,
    });
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(ReadingCoverCalendar(calendar: _calendario())),
    );
    await tester.pumpAndSettle();

    expect(_dia(4, 'Terminado'), findsNothing);
    expect(_dia(5, 'Terminado'), findsOneWidget);
    semantics.dispose();
  });
}
