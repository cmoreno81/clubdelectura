import 'package:club_lectura_app/models/book_of_year.dart';
import 'package:club_lectura_app/models/club_book_of_year.dart';
import 'package:club_lectura_app/widgets/dashboard/club_books_of_year_card.dart';
import 'package:club_lectura_app/widgets/common/club_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('un participante se muestra completo y con estado inicial', (
    tester,
  ) async {
    await _pump(tester, members: [_member('Cristina')], current: 'Cristina');

    expect(find.text('1 participante'), findsOneWidget);
    expect(find.text('Tú'), findsOneWidget);
    expect(find.text('Todavía no ha empezado'), findsOneWidget);
    expect(find.text('Ver todos'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('separa la elección colectiva de las elecciones personales', (
    tester,
  ) async {
    var collectiveLoads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClubBooksOfYearCard(
            currentUserName: 'Cristina',
            loadMembers: (_) async => [_member('Cristina')],
            loadEdition: (_) async {
              collectiveLoads++;
              return _edition(status: 'ROUND_OPEN');
            },
            collectivePageBuilder: (_) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    Navigator.pop(tester.element(find.byType(TextButton))),
                child: const Text('Cerrar colectiva'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('El año del club'), findsOneWidget);
    expect(find.text('Libro del año del club'), findsOneWidget);
    expect(find.text('Elecciones de los miembros'), findsOneWidget);
    expect(find.text('Descubre sus cuadros personales'), findsOneWidget);
    expect(find.textContaining('Vota ahora'), findsOneWidget);

    await tester.tap(find.text('Libro del año del club'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar colectiva'));
    await tester.pumpAndSettle();
    expect(collectiveLoads, 2);
  });

  testWidgets('PREPARING muestra candidatas y no anuncia votación abierta', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClubBooksOfYearCard(
            loadMembers: (_) async => const [],
            loadEdition: (_) async => _edition(
              status: 'PREPARING',
              candidatesSyncedAt: DateTime(2026, 8, 15),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Edición en preparación'), findsOneWidget);
    expect(find.text('Revisar candidatas'), findsOneWidget);
    expect(find.textContaining('1 lecturas candidatas'), findsOneWidget);
    expect(find.textContaining('Vota ahora'), findsNothing);
  });

  testWidgets('usa una identidad lavanda legible en tema claro y oscuro', (
    tester,
  ) async {
    await _pump(tester, members: [_member('Cristina')]);
    final light = tester.widget<ClubCard>(find.byType(ClubCard));
    expect(light.gradient, isA<LinearGradient>());
    final lightColors = (light.gradient! as LinearGradient).colors;

    await _pump(
      tester,
      members: [_member('Cristina')],
      brightness: Brightness.dark,
    );
    final dark = tester.widget<ClubCard>(find.byType(ClubCard));
    expect((dark.gradient! as LinearGradient).colors, isNot(lightColors));
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordena la cuenta actual primero y elimina duplicados', (
    tester,
  ) async {
    await _pump(
      tester,
      current: 'Cristina',
      members: [
        _member('Ana', months: 2),
        _member('Cristina', months: 7),
        _member('ana', months: 8),
        _member('Bea', months: 3),
      ],
    );

    expect(find.text('3 participantes'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Tú')).dx,
      lessThan(tester.getTopLeft(find.text('Ana')).dx),
    );
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('muestra finalistas, ganador y semántica accesible', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      current: 'Cristina',
      members: [
        _member('Cristina', months: 7, finalists: [_book('f1'), _book('f2')]),
        _member(
          'Beatriz',
          months: 12,
          winner: _book('winner', title: 'La elegida'),
        ),
      ],
    );

    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('7 de 12 meses elegidos')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Libro del año elegido: La elegida')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('más de diez participantes usa carrusel y acción Ver todos', (
    tester,
  ) async {
    final members = List.generate(12, (index) => _member('Miembro $index'));
    await _pump(tester, members: members, size: const Size(360, 700));

    final carousel = find.byKey(const ValueKey('club-books-of-year-carousel'));
    expect(find.text('12 participantes'), findsOneWidget);
    expect(find.text('Ver todos'), findsNothing);
    await tester.drag(carousel, const Offset(-3000, 0));
    await tester.pumpAndSettle();
    expect(find.text('Ver todos'), findsOneWidget);
    expect(tester.getSize(carousel).height, 222);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Ver todos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver todos'));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
  });

  testWidgets('abre el cuadro propio editable y el ajeno en consulta', (
    tester,
  ) async {
    final opened = <String?>[];
    var loads = 0;
    await _pump(
      tester,
      current: 'Cristina',
      members: [_member('Cristina'), _member('Álex')],
      onLoad: () => loads++,
      pageBuilder: (profile, _) {
        opened.add(profile);
        return Scaffold(
          body: TextButton(
            onPressed: () =>
                Navigator.pop(tester.element(find.byType(TextButton))),
            child: const Text('Cerrar'),
          ),
        );
      },
    );

    await tester.tap(find.text('Tú'));
    await tester.pumpAndSettle();
    expect(opened, [null]);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(loads, 2);

    await tester.tap(find.text('Álex'));
    await tester.pumpAndSettle();
    expect(opened, [null, 'Álex']);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(loads, 2);
  });

  testWidgets(
    'nombres largos y portadas ausentes no desbordan con texto grande',
    (tester) async {
      await _pump(
        tester,
        size: const Size(320, 700),
        textScaler: const TextScaler.linear(1.6),
        members: [
          _member(
            'Un nombre de miembro extraordinariamente largo',
            months: 9,
            finalists: [_book('f1'), _book('f2')],
          ),
          _member(
            'Otra persona',
            winner: _book('w', title: 'Ganador sin portada'),
          ),
        ],
      );

      expect(find.byIcon(Icons.menu_book), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<ClubBookOfYearMember> members,
  String? current,
  Size size = const Size(390, 760),
  TextScaler textScaler = TextScaler.noScaling,
  VoidCallback? onLoad,
  Widget Function(String? profile, int year)? pageBuilder,
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ClubBooksOfYearCard(
              currentUserName: current,
              loadEdition: (_) async => null,
              loadMembers: (_) async {
                onLoad?.call();
                return members;
              },
              pageBuilder: pageBuilder,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ClubBookOfYearMember _member(
  String name, {
  int months = 0,
  List<BookOfYearBook> finalists = const [],
  BookOfYearBook? winner,
}) => ClubBookOfYearMember(
  userName: name,
  avatarUrl: '',
  completedMonths: months,
  selections: months == 0 ? const [] : [_book('selection-$name')],
  finalists: finalists,
  winner: winner,
);

BookOfYearBook _book(String id, {String? title}) => BookOfYearBook(
  id: id,
  title: title ?? 'Libro $id',
  coverUrl: '',
  authorName: 'Autor',
);

ClubBookOfYearEdition _edition({
  required String status,
  bool canAdmin = false,
  DateTime? candidatesSyncedAt,
}) => ClubBookOfYearEdition(
  clubName: 'Club de prueba',
  year: DateTime.now().year,
  status: status,
  canAdmin: canAdmin,
  candidates: const [
    ClubBookOfYearCandidate(
      id: 'c1',
      bookId: 'b1',
      title: 'Candidata',
      coverUrl: '',
      authorName: '',
    ),
  ],
  myQualifyingVotes: const [],
  rounds: const [],
  candidatesSyncedAt: candidatesSyncedAt,
);
