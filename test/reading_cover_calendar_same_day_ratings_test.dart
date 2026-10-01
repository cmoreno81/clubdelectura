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

      // Modo abanico (tarjeta para compartir): las portadas de ese día se
      // superponen todas a la vez, así que ambas valoraciones deben verse
      // directamente sin tocar nada.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReadingCoverCalendar(
                calendar: calendar,
                highResolution: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Antes del fix, solo se conservaba la valoración más alta (4.5) y la
      // del otro libro (2.5) desaparecía del todo.
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('2.5'), findsOneWidget);

      // Modo app: solo se ve una portada por el poco espacio, pero al tocar
      // el día se abre la lista con los dos libros y conserva cada rating.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReadingCoverCalendar(
                calendar: calendar,
                onBookTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Solo se ve "Libro Uno" en la celda (la primera lectura de ese día);
      // tocarla abre la lista con ambos libros.
      await tester.tap(find.text('Libro Uno'));
      await tester.pumpAndSettle();

      // findsWidgets porque cada fila de la lista también muestra el título
      // como texto de respaldo en su miniatura (sin portada real en el test).
      expect(find.text('Libro Uno'), findsWidgets);
      expect(find.text('Libro Dos'), findsWidgets);
    },
  );
}
