import 'package:club_lectura_app/pages/wrapped_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra favoritos y permite navegar hasta su diapositiva', (
    tester,
  ) async {
    await _pumpWrapped(
      tester,
      data: _data(
        favorites: [
          _book('Favorito uno', author: 'Autor uno'),
          _book('Favorito dos', author: ''),
        ],
      ),
    );

    await _advanceUntil(tester, 'Los favoritos\nque te acompañan');
    expect(find.byKey(const ValueKey('wrapped-favorites')), findsOneWidget);
    expect(find.text('Favorito uno'), findsOneWidget);
    expect(find.text('Autor uno'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('omite favoritos y cuadro cuando ambos están vacíos', (
    tester,
  ) async {
    await _pumpWrapped(tester, data: _data());

    await _visitAllPages(tester);
    expect(find.text('Los favoritos\nque te acompañan'), findsNothing);
    expect(find.text('Tu cuadro está\nen marcha'), findsNothing);
    expect(find.text('Tu Libro del año'), findsNothing);
  });

  testWidgets('muestra un cuadro en curso sin insinuar ganador', (
    tester,
  ) async {
    await _pumpWrapped(
      tester,
      data: _data(
        bookOfYear: {
          'status': 'IN_PROGRESS',
          'completedMonths': 7,
          'finalists': <dynamic>[],
          'winner': null,
        },
      ),
    );

    await _advanceUntil(tester, 'Tu cuadro está\nen marcha');
    expect(find.text('7 de 12'), findsOneWidget);
    expect(find.text('Tu Libro del año'), findsNothing);
  });

  testWidgets('muestra finalistas sin elegir ganador automáticamente', (
    tester,
  ) async {
    await _pumpWrapped(
      tester,
      data: _data(
        bookOfYear: {
          'status': 'FINALISTS',
          'completedMonths': 12,
          'finalists': [_book('Finalista A'), _book('Finalista B')],
          'winner': null,
        },
      ),
    );

    await _advanceUntil(tester, 'Tu cuadro todavía\nbusca un ganador');
    expect(find.text('Tu Libro del año'), findsNothing);
    expect(find.text('👑'), findsNothing);
  });

  testWidgets('muestra Libro del año completado y lo incorpora al resumen', (
    tester,
  ) async {
    await _pumpWrapped(
      tester,
      data: _data(
        favorites: [_book('Favorito')],
        bookOfYear: {
          'status': 'COMPLETED',
          'completedMonths': 12,
          'finalists': [_book('Finalista')],
          'winner': _book('Libro ganador', author: 'Autor ganador'),
        },
      ),
    );

    await _advanceUntil(tester, 'Tu Libro del año');
    expect(find.text('Libro ganador'), findsOneWidget);
    expect(find.text('Autor ganador'), findsOneWidget);
    await _visitAllPages(tester);
    expect(find.text('Libro ganador'), findsOneWidget);
  });

  testWidgets(
    'no desborda en móvil estrecho con texto ampliado e imágenes ausentes',
    (tester) async {
      await _pumpWrapped(
        tester,
        size: const Size(320, 640),
        textScaler: const TextScaler.linear(1.35),
        data: _data(
          favorites: List.generate(5, (i) => _book('Favorito largo número $i')),
          bookOfYear: {
            'status': 'FINALISTS',
            'completedMonths': 12,
            'finalists': [_book('A'), _book('B'), _book('C')],
            'winner': null,
          },
        ),
      );

      await _jumpToPage(tester, 3);
      expect(find.byKey(const ValueKey('wrapped-favorites')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _jumpToPage(tester, 6);
      expect(find.text('Tu cuadro todavía\nbusca un ganador'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpWrapped(
  WidgetTester tester, {
  required Map<String, dynamic> data,
  Size size = const Size(390, 760),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: WrappedPage(anio: 2025, loadData: (_) async => data),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _advanceUntil(WidgetTester tester, String text) async {
  for (var i = 0; i < 16 && find.text(text).evaluate().isEmpty; i++) {
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
  }
  expect(find.text(text), findsOneWidget);
}

Future<void> _visitAllPages(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
  }
}

Future<void> _jumpToPage(WidgetTester tester, int page) async {
  final pageView = tester.widget<PageView>(find.byType(PageView));
  pageView.controller!.jumpToPage(page);
  await tester.pumpAndSettle();
}

Map<String, dynamic> _data({
  List<Map<String, dynamic>> favorites = const [],
  Map<String, dynamic>? bookOfYear,
}) => {
  'totalBooks': 2,
  'totalPages': 500,
  'totalActiveDays': 20,
  'streak': 3,
  'topGenre': null,
  'topAuthor': null,
  'bestMonth': null,
  'avgRating': null,
  'longestBook': null,
  'firstBook': null,
  'diffVsPrevYear': 1,
  'prevYearBooks': 1,
  'byMonth': List<int>.filled(12, 0),
  'books': <dynamic>[],
  'favoriteBooks': favorites,
  'bookOfYear':
      bookOfYear ??
      {
        'status': 'NOT_STARTED',
        'completedMonths': 0,
        'finalists': <dynamic>[],
        'winner': null,
      },
};

Map<String, dynamic> _book(String title, {String author = 'Autor'}) => {
  'id': title,
  'title': title,
  'coverUrl': '',
  'authorName': author,
};
