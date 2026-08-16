import 'dart:async';
import 'dart:io';
import 'package:club_lectura_app/models/book_of_year.dart';
import 'package:club_lectura_app/pages/book_of_year_page.dart';
import 'package:club_lectura_app/widgets/profile/book_of_year_preview.dart';
import 'package:club_lectura_app/widgets/book_of_year/book_of_year_bracket.dart';
import 'package:club_lectura_app/widgets/book_of_year/book_of_year_bracket_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cambia de año y el cuadro público permanece de solo lectura', (
    tester,
  ) async {
    final years = <int>[];
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: BookOfYearPage(
          profile: 'Ada',
          initialYear: DateTime.now().year,
          loadBoard: (year, editable) async {
            years.add(year);
            expect(editable, isFalse);
            return _board(year, editable: false);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Libro del año'), findsWidgets);
    expect(find.text('Pendiente'), findsWidgets);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().year - 1}').last);
    await tester.pumpAndSettle();
    expect(years, [DateTime.now().year, DateTime.now().year - 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('indica el desplazamiento y oculta el degradado al final', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: BookOfYearPage(
          loadBoard: (_, _) async =>
              _board(DateTime.now().year, editable: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Desliza para ver las rondas'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    AnimatedOpacity fade() => tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('book-of-year-right-fade')),
    );
    expect(fade().opacity, 1);

    final horizontalScroll = find.byKey(
      const ValueKey('book-of-year-horizontal-scroll'),
    );
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: horizontalScroll, matching: find.byType(Scrollable)),
    );
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(fade().opacity, 0);
    expect(tester.takeException(), isNull);
  });

  test('el perfil ajeno integra la vista previa como solo lectura', () {
    final source = File(
      'lib/pages/perfil_usuario_page.dart',
    ).readAsStringSync();
    expect(source, contains('BookOfYearPreview('));
    expect(source, contains('profileUserId:'));
    expect(source, contains('editable: esMiPerfil'));
    final preview = File(
      'lib/widgets/profile/book_of_year_preview.dart',
    ).readAsStringSync();
    expect(preview, contains("ValueKey('book-of-year-empty-state')"));
    expect(
      preview,
      contains('profile: widget.editable ? null : widget.profile'),
    );
  });

  testWidgets(
    'guardar la elección actualiza enero sin excepción ni repetir el POST',
    (tester) async {
      var saves = 0;
      final candidate = _book('page-21', 'Página 21');
      final initial = _boardWithSelections(
        DateTime.now().year,
        editable: true,
        eligible: {
          1: [candidate],
        },
      );
      final saved = _boardWithSelections(
        DateTime.now().year,
        editable: true,
        selections: {1: candidate},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BookOfYearPage(
            loadBoard: (_, _) async => initial,
            saveMonth: (year, month, bookId) async {
              saves++;
              expect(month, 1);
              expect(bookId, 'page-21');
              return saved;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bracket-month-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Página 21').last);
      await tester.pumpAndSettle();

      expect(saves, 1);
      expect(find.text('Página 21'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'al volver al perfil recarga una vez y muestra dos portadas con sus meses',
    (tester) async {
      var loads = 0;
      final january = _book('jan', 'Enero elegido');
      final february = _book('feb', 'Febrero elegido');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookOfYearPreview(
              profile: 'Ada',
              editable: true,
              loadBoard: (_, _) async {
                loads++;
                return loads == 1
                    ? _boardWithSelections(DateTime.now().year, editable: true)
                    : _boardWithSelections(
                        DateTime.now().year,
                        editable: true,
                        selections: {1: january, 2: february},
                      );
              },
              pageBuilder: (_, _) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      Navigator.pop(tester.element(find.text('Volver'))),
                  child: const Text('Volver'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(loads, 1);
      expect(find.byType(BookOfYearBracketPreview), findsNothing);
      expect(find.text('Empezar mi Libro del año'), findsOneWidget);

      await tester.tap(find.text('Empezar mi Libro del año'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();

      expect(loads, 2);
      expect(find.text('2 de 12 meses elegidos'), findsNWidgets(2));
      expect(find.byKey(const ValueKey('preview-book-jan')), findsWidgets);
      expect(find.byKey(const ValueKey('preview-book-feb')), findsWidgets);

      await tester.pump();
      expect(loads, 2);
    },
  );

  testWidgets(
    'un duelo bloqueado enseña enero y febrero pero no permite votar',
    (tester) async {
      var votes = 0;
      final january = _book('jan', 'Libro enero');
      final february = _book('feb', 'Libro febrero');
      final board = _boardWithSelections(
        DateTime.now().year,
        editable: true,
        selections: {1: january, 2: february},
        duels: [
          BookOfYearDuel(
            phase: 'MONTH_PAIR',
            position: 1,
            automatic: false,
            unlocked: false,
            candidates: [january, february],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BookOfYearPage(
            loadBoard: (_, _) async => board,
            chooseDuel: (year, phase, position, bookId) async {
              votes++;
              return board;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('bracket-first-1')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Libro enero'), findsWidgets);
      expect(find.text('Libro febrero'), findsWidgets);
      expect(find.text('Bloqueada'), findsWidgets);
      final blockedSlot = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(const ValueKey('bracket-duel-MONTH_PAIR-1-jan')),
          matching: find.byType(InkWell),
        ),
      );
      expect(blockedSlot.onTap, isNull);
      expect(votes, 0);
    },
  );

  testWidgets(
    'un cuadro propio vacío ofrece empezar sin mostrar el cuadrante',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookOfYearPreview(
              profile: 'Ada',
              editable: true,
              loadBoard: (_, _) async =>
                  _boardWithSelections(DateTime.now().year, editable: true),
              pageBuilder: (_, _) =>
                  const Scaffold(body: Text('Configuración')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BookOfYearBracketPreview), findsNothing);
      expect(find.text('Empezar mi Libro del año'), findsOneWidget);
      await tester.tap(find.text('Empezar mi Libro del año'));
      await tester.pumpAndSettle();
      expect(find.text('Configuración'), findsOneWidget);
    },
  );

  testWidgets('un cuadro público vacío permanece visible y es de consulta', (
    tester,
  ) async {
    final year = DateTime.now().year;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookOfYearPreview(
            profile: 'Bea',
            profileUserId: 'bea-id',
            editable: false,
            loadBoard: (_, _) async => _board(year, editable: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Libro del año'), findsOneWidget);
    expect(
      find.text('Todavía no ha comenzado su Libro del año $year'),
      findsOneWidget,
    );
    expect(find.byType(BookOfYearBracketPreview), findsNothing);
    expect(find.text('Empezar mi Libro del año'), findsNothing);
    expect(find.text('Ver cuadro completo'), findsNothing);
  });

  testWidgets('carga, error y reintento no se confunden con el estado vacío', (
    tester,
  ) async {
    final first = Completer<BookOfYearBoard>();
    var loads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookOfYearPreview(
            profile: 'Bea',
            profileUserId: 'bea-id',
            editable: false,
            loadBoard: (_, _) {
              loads++;
              if (loads == 1) return first.future;
              return Future.value(_board(DateTime.now().year, editable: false));
            },
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Todavía no ha comenzado'), findsNothing);

    first.completeError(Exception('sin conexión'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo cargar Libro del año'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('Todavía no ha comenzado'), findsNothing);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(find.textContaining('Todavía no ha comenzado'), findsOneWidget);
  });

  testWidgets(
    'parcial, finalistas y ganador muestran la previsualización real',
    (tester) async {
      final year = DateTime.now().year;
      final partial = _boardWithSelections(
        year,
        editable: false,
        selections: {1: _book('jan', 'Enero')},
      );
      final finalists = _boardWithSelections(
        year,
        editable: false,
        finalists: [_book('f1', 'Finalista 1'), _book('f2', 'Finalista 2')],
      );
      final winner = _boardWithSelections(
        year,
        editable: false,
        winner: _book('winner', 'Ganador'),
      );

      for (final board in [partial, finalists, winner]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookOfYearPreview(
                profile: 'Bea',
                profileUserId: 'bea-id',
                editable: false,
                loadBoard: (_, _) async => board,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BookOfYearBracketPreview), findsOneWidget);
        expect(find.text('Ver cuadro completo'), findsOneWidget);
      }
    },
  );

  testWidgets('dos perfiles homónimos recargan siempre mediante su userId', (
    tester,
  ) async {
    final loaded = <String>[];
    Widget app(String id) => MaterialApp(
      home: Scaffold(
        body: BookOfYearPreview(
          profile: 'Bea',
          profileUserId: id,
          editable: false,
          loadBoard: (_, _) async {
            loaded.add(id);
            return _board(DateTime.now().year, editable: false);
          },
        ),
      ),
    );

    await tester.pumpWidget(app('bea-a'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app('bea-b'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app('bea-a'));
    await tester.pumpAndSettle();

    expect(loaded, ['bea-a', 'bea-b', 'bea-a']);
  });

  testWidgets(
    'la vista previa competitiva no desborda en móvil con texto ampliado',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final january = _book('jan-preview', 'Un enero con título muy largo');
      final board = _boardWithSelections(
        DateTime.now().year,
        editable: true,
        selections: {1: january},
        duels: [
          BookOfYearDuel(
            phase: 'MONTH_PAIR',
            position: 1,
            automatic: false,
            unlocked: false,
            candidates: [january],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: BookOfYearPreview(
                  profile: 'Ada',
                  editable: true,
                  loadBoard: (_, _) async => board,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BookOfYearBracketPreview), findsOneWidget);
      expect(
        find.byKey(const ValueKey('book-of-year-preview-connections')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('preview-book-jan-preview')),
        findsWidgets,
      );
      expect(
        find.byKey(const ValueKey('preview-annual-winner')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Abrir cuadro completo de Libro del año'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('elegir ganadora conserva el duelo visible y el scroll', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 620));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final january = _book('jan', 'Libro enero');
    final february = _book('feb', 'Libro febrero');
    final duel = BookOfYearDuel(
      phase: 'MONTH_PAIR',
      position: 1,
      automatic: false,
      unlocked: true,
      candidates: [january, february],
    );
    final initial = _boardWithSelections(
      DateTime.now().year,
      editable: true,
      selections: {1: january, 2: february},
      duels: [duel],
    );
    final chosen = _boardWithSelections(
      DateTime.now().year,
      editable: true,
      selections: {1: january, 2: february},
      duels: [
        BookOfYearDuel(
          phase: duel.phase,
          position: duel.position,
          automatic: false,
          unlocked: true,
          candidates: duel.candidates,
          winner: january,
        ),
      ],
    );
    final mutation = Completer<BookOfYearBoard>();

    await tester.pumpWidget(
      MaterialApp(
        home: BookOfYearPage(
          loadBoard: (_, _) async => initial,
          chooseDuel: (_, _, _, _) => mutation.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final slot = find.byKey(const ValueKey('bracket-duel-MONTH_PAIR-1-jan'));
    await tester.scrollUntilVisible(
      slot,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    final vertical = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final horizontalFinder = find.descendant(
      of: find.byKey(const ValueKey('book-of-year-horizontal-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.drag(
      find.byKey(const ValueKey('book-of-year-horizontal-scroll')),
      const Offset(-280, 0),
    );
    await tester.pumpAndSettle();
    final horizontal = tester.state<ScrollableState>(horizontalFinder);
    final verticalBefore = vertical.position.pixels;
    final horizontalBefore = horizontal.position.pixels;
    expect(verticalBefore, greaterThan(0));
    expect(horizontalBefore, greaterThan(0));

    tester
        .widget<InkWell>(
          find.descendant(of: slot, matching: find.byType(InkWell)),
        )
        .onTap!();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(slot, findsOneWidget);
    expect(vertical.position.pixels, closeTo(verticalBefore, 0.1));
    expect(horizontal.position.pixels, closeTo(horizontalBefore, 0.1));
    mutation.complete(chosen);
    await tester.pumpAndSettle();

    expect(vertical.position.pixels, closeTo(verticalBefore, 0.1));
    expect(horizontal.position.pixels, closeTo(horizontalBefore, 0.1));
    expect(find.text('Libro elegido'), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(
            find.descendant(of: slot, matching: find.byType(Semantics)).first,
          )
          .properties
          .selected,
      isTrue,
    );
    expect(slot, findsOneWidget);
  });

  testWidgets('una única candidata queda pendiente hasta pulsarla', (
    tester,
  ) async {
    final january = _book('jan', 'Libro enero');
    final board = _boardWithSelections(
      DateTime.now().year,
      editable: true,
      selections: {1: january},
      duels: [
        BookOfYearDuel(
          phase: 'MONTH_PAIR',
          position: 1,
          automatic: false,
          unlocked: true,
          candidates: [january],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: BookOfYearPage(loadBoard: (_, _) async => board)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('bracket-first-1')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pendiente'), findsWidgets);
    expect(find.text('Libro elegido'), findsNothing);
    final candidate = find.byKey(
      const ValueKey('bracket-duel-MONTH_PAIR-1-jan'),
    );
    expect(
      tester
          .widget<Semantics>(
            find
                .descendant(of: candidate, matching: find.byType(Semantics))
                .first,
          )
          .properties
          .selected,
      isFalse,
    );
    final slot = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('bracket-duel-MONTH_PAIR-1-jan')),
        matching: find.byType(InkWell),
      ),
    );
    expect(slot.onTap, isNotNull);
  });

  testWidgets('el cuadro gráfico contiene cuatro columnas y conexiones', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: BookOfYearBracket(
              board: _board(DateTime.now().year, editable: true),
              year: DateTime.now().year,
              onChooseMonth: (_) {},
              onChooseDuel: (_, _) {},
              onChooseWinner: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Meses'), findsOneWidget);
    expect(find.text('Primera ronda'), findsOneWidget);
    expect(find.text('Finalistas'), findsOneWidget);
    expect(find.text('Libro del año'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('book-of-year-connections')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('bracket-locked-slot')), findsWidgets);
    expect(find.byKey(const ValueKey('bracket-pending-slot')), findsOneWidget);
  });

  testWidgets(
    'títulos largos y portadas ausentes funcionan en móvil y tablet',
    (tester) async {
      final longBook = _book(
        'long',
        'Un título extraordinariamente largo que debe truncarse sin desbordar',
      );
      final board = _boardWithSelections(
        DateTime.now().year,
        editable: true,
        selections: {1: longBook},
        duels: [
          BookOfYearDuel(
            phase: 'MONTH_PAIR',
            position: 1,
            automatic: false,
            unlocked: true,
            candidates: [longBook],
          ),
        ],
      );
      for (final size in [const Size(320, 640), const Size(800, 1000)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(home: BookOfYearPage(loadBoard: (_, _) async => board)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.menu_book_outlined), findsWidgets);
      }
      await tester.binding.setSurfaceSize(null);
    },
  );
}

BookOfYearBook _book(String id, String title) =>
    BookOfYearBook(id: id, title: title, coverUrl: '', authorName: 'Autora');

BookOfYearBoard _boardWithSelections(
  int year, {
  required bool editable,
  Map<int, BookOfYearBook> selections = const {},
  Map<int, List<BookOfYearBook>> eligible = const {},
  List<BookOfYearDuel> duels = const [],
  List<BookOfYearBook> finalists = const [],
  BookOfYearBook? winner,
}) => BookOfYearBoard(
  year: year,
  editable: editable,
  userName: 'Ada',
  avatarUrl: '',
  hasSelections: selections.isNotEmpty,
  months: List.generate(
    12,
    (index) => BookOfYearMonth(
      month: index + 1,
      locked: false,
      finished: true,
      eligible: eligible[index + 1] ?? const [],
      selection: selections[index + 1],
    ),
  ),
  duels: duels,
  finalists: finalists,
  winner: winner,
);

BookOfYearBoard _board(int year, {required bool editable}) => BookOfYearBoard(
  year: year,
  editable: editable,
  userName: 'Ada',
  avatarUrl: '',
  hasSelections: false,
  months: List.generate(
    12,
    (index) => BookOfYearMonth(
      month: index + 1,
      locked: index > 7,
      finished: index < 7,
      eligible: const [],
    ),
  ),
  duels: const [],
  finalists: const [],
);
