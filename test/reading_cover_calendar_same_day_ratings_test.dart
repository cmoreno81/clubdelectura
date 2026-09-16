import 'package:club_lectura_app/models/general_dashboard.dart';
import 'package:club_lectura_app/widgets/common/reading_cover_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'dos libros terminados el mismo día muestran cada uno su propia valoración',
    (tester) async {
      const finishDate = '2026-09-05T12:00:00.000Z';

      final calendar = ReadingCalendar(
        year: 2026,
        month: 9,
        events: const [],
        readings: const [
          MonthlyReadingSpan(
            id: 'completion:c1',
            libraryId: 'lib1',
            bookId: 'book1',
            title: 'Libro Uno',
            coverUrl: '',
            startedAt: finishDate,
            finishedAt: finishDate,
          ),
          MonthlyReadingSpan(
            id: 'completion:c2',
            libraryId: 'lib2',
            bookId: 'book2',
            title: 'Libro Dos',
            coverUrl: '',
            startedAt: finishDate,
            finishedAt: finishDate,
          ),
        ],
        finishedBooks: const [
          MonthlyFinishedBook(
            id: 'c1:book1',
            bookId: 'book1',
            title: 'Libro Uno',
            coverUrl: '',
            finishedAt: finishDate,
            pages: 300,
            rating: 4.5,
          ),
          MonthlyFinishedBook(
            id: 'c2:book2',
            bookId: 'book2',
            title: 'Libro Dos',
            coverUrl: '',
            finishedAt: finishDate,
            pages: 250,
            rating: 2.5,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReadingCoverCalendar(calendar: calendar),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Antes del fix, solo se conservaba la valoración más alta (4.5) y la
      // del otro libro (2.5) desaparecía del todo.
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('2.5'), findsOneWidget);
    },
  );
}
