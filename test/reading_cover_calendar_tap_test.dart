import 'package:club_lectura_app/models/general_dashboard.dart';
import 'package:club_lectura_app/widgets/common/reading_cover_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MonthlyReadingSpan _lectura(String id, String titulo, String ini, String fin) =>
    MonthlyReadingSpan(
      id: 'library:$id',
      libraryId: id,
      bookId: id,
      title: titulo,
      coverUrl: '',
      startedAt: ini,
      finishedAt: fin,
    );

void main() {
  testWidgets(
    'tocar un día con un solo libro abre la edición de sus fechas; con varios, la lista',
    (tester) async {
      final calendar = ReadingCalendar(
        year: 2026,
        month: 10,
        events: const [],
        readings: [
          _lectura(
            'a',
            'Libro A',
            '2026-10-01T12:00:00.000Z',
            '2026-10-05T12:00:00.000Z',
          ),
          _lectura(
            'b',
            'Libro B',
            '2026-10-05T12:00:00.000Z',
            '2026-10-08T12:00:00.000Z',
          ),
        ],
      );
      final tocados = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReadingCoverCalendar(
                calendar: calendar,
                soloDiaDeFin: false,
                onBookTap: (r) => tocados.add(r.title),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Día 2: solo el libro A.
      await tester.tap(find.byKey(const Key('calendario-dia-2')));
      await tester.pumpAndSettle();
      expect(tocados, ['Libro A']);

      // Día 6: solo el libro B.
      await tester.tap(find.byKey(const Key('calendario-dia-6')));
      await tester.pumpAndSettle();
      expect(tocados, ['Libro A', 'Libro B']);
    },
  );
}
