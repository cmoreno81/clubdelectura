import 'package:club_lectura_app/models/general_dashboard.dart';
import 'package:club_lectura_app/widgets/dashboard/year_reading_shelf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('permite mostrar primero las lecturas más recientes', (
    tester,
  ) async {
    final books = List.generate(13, (index) {
      final day = 13 - index;
      return YearShelfBook(
        id: 'completion-$day',
        bookId: 'book-$day',
        title: 'Libro ${day.toString().padLeft(2, '0')}',
        coverUrl: '',
        finishedAt: '2026-01-${day.toString().padLeft(2, '0')}T12:00:00Z',
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: YearReadingShelf(
              year: 2026,
              books: books,
              onBookTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Ordenar biblioteca anual'));
    await tester.pumpAndSettle();
    final moreRecentItem = find.ancestor(
      of: find.text('Primero del año'),
      matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
    );
    await tester.tap(moreRecentItem);
    await tester.pump();

    expect(find.text('Libro 13'), findsOneWidget);
    expect(find.text('Libro 02'), findsOneWidget);
    expect(find.text('Libro 01'), findsNothing);

    await tester.tap(find.text('Ver las 13 lecturas'));
    await tester.pump();

    expect(find.text('Libro 01'), findsOneWidget);
  });

  testWidgets('la biblioteca anual comienza por la lectura más reciente', (
    tester,
  ) async {
    final books = List.generate(13, (index) {
      final day = 13 - index;
      return YearShelfBook(
        id: 'completion-$day',
        bookId: 'book-$day',
        title: 'Libro ${day.toString().padLeft(2, '0')}',
        coverUrl: '',
        finishedAt: '2026-01-${day.toString().padLeft(2, '0')}T12:00:00Z',
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: YearReadingShelf(
              year: 2026,
              books: books,
              onBookTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Ordenar biblioteca anual'));
    await tester.pumpAndSettle();
    final firstReadItem = find.ancestor(
      of: find.text('Primero del año'),
      matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
    );
    await tester.tap(firstReadItem);
    await tester.pump();

    expect(find.text('Libro 13'), findsOneWidget);
    expect(find.text('Libro 02'), findsOneWidget);
    expect(find.text('Libro 01'), findsNothing);

    await tester.tap(find.text('Ver las 13 lecturas'));
    await tester.pump();

    expect(find.text('Libro 13'), findsOneWidget);
  });

  testWidgets('permite mostrar primero las lecturas más antiguas', (
    tester,
  ) async {
    final books = List.generate(13, (index) {
      final day = index + 1;
      return YearShelfBook(
        id: 'completion-$day',
        bookId: 'book-$day',
        title: 'Libro ${day.toString().padLeft(2, '0')}',
        coverUrl: '',
        finishedAt: '2026-01-${day.toString().padLeft(2, '0')}T12:00:00Z',
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: YearReadingShelf(
              year: 2026,
              books: books,
              onBookTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Ordenar biblioteca anual'));
    await tester.pumpAndSettle();
    final oldestFirstItem = find.ancestor(
      of: find.text('Más recientes primero'),
      matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
    );
    await tester.tap(oldestFirstItem);
    await tester.pump();

    expect(find.text('Libro 01'), findsOneWidget);
    expect(find.text('Libro 12'), findsOneWidget);
    expect(find.text('Libro 13'), findsNothing);
  });

  testWidgets('el orden aleatorio aparece seleccionado inicialmente', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: YearReadingShelf(
            year: 2026,
            books: const [],
            onBookTap: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Ordenar biblioteca anual'));
    await tester.pumpAndSettle();

    final randomItem = tester.widget<CheckedPopupMenuItem<dynamic>>(
      find.ancestor(
        of: find.text('Orden aleatorio'),
        matching: find.byWidgetPredicate(
          (widget) => widget is CheckedPopupMenuItem<dynamic>,
        ),
      ),
    );
    expect(randomItem.checked, isTrue);
  });

  testWidgets('muestra diferente orden cuando las fechas son iguales', (
    tester,
  ) async {
    final books = List.generate(15, (index) {
      return YearShelfBook(
        id: 'completion-$index',
        bookId: 'book-$index',
        title: 'Libro ${(index + 1).toString().padLeft(2, '0')}',
        coverUrl: '',
        finishedAt: '2026-01-15T12:00:00Z',
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: YearReadingShelf(
              year: 2026,
              books: books,
              onBookTap: (_) {},
            ),
          ),
        ),
      ),
    );

    // Select "Primero del año" - should show 15-04 (reversed)
    await tester.tap(find.byTooltip('Ordenar biblioteca anual'));
    await tester.pumpAndSettle();
    var firstReadItem = find.ancestor(
      of: find.text('Primero del año'),
      matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
    );
    await tester.tap(firstReadItem);
    await tester.pumpAndSettle();

    // Should show Libro 15-04
    expect(find.text('Libro 15'), findsOneWidget);
    expect(find.text('Libro 04'), findsOneWidget);
    // 01-03 should not be visible (not expanded)
    expect(find.text('Libro 01'), findsNothing);

    // Change to "Más recientes primero" - should show 01-12
    await tester.tap(find.byTooltip('Ordenar biblioteca anual'));
    await tester.pumpAndSettle();
    final latestFirstItem = find.ancestor(
      of: find.text('Más recientes primero'),
      matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
    );
    await tester.tap(latestFirstItem);
    await tester.pumpAndSettle();

    // With normal order by index when dates are equal, should show 01-12
    expect(find.text('Libro 01'), findsOneWidget);
    expect(find.text('Libro 12'), findsOneWidget);
    // 13-15 should not be visible
    expect(find.text('Libro 13'), findsNothing);
  });
}
