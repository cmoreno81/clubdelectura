import 'package:club_lectura_app/models/reaction_details.dart';
import 'package:club_lectura_app/widgets/common/reaction_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final details = ReactionDetails.fromJson({
    'total': 3,
    'grupos': [
      {
        'reaccion': 'LIKE',
        'usuarios': [
          {
            'id': 'me',
            'nombre': 'Cristina',
            'avatarUrl': '',
            'esTu': true,
            'fecha': '2026-08-01T09:00:00.000Z',
          },
          {
            'id': 'bea',
            'nombre': 'Bea',
            'avatarUrl': '',
            'esTu': false,
            'fecha': '2026-08-01T10:00:00.000Z',
          },
        ],
      },
      {
        'reaccion': 'CLAP',
        'usuarios': [
          {
            'id': 'ana',
            'nombre': 'Ana',
            'avatarUrl': '',
            'esTu': false,
            'fecha': '2026-08-01T11:00:00.000Z',
          },
        ],
      },
    ],
  });

  testWidgets('muestra Todas, filtra por emoji e identifica Tú', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReactionDetailsSheet(
            targetType: 'COMMENT',
            targetId: 'comment-1',
            loader: () async => details,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Todas 3'), findsOneWidget);
    expect(find.text('Tú'), findsOneWidget);
    expect(find.text('Bea'), findsOneWidget);
    await tester.tap(find.text('👏 1'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Bea'), findsNothing);
  });

  testWidgets('muestra vacío y permite actualizar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReactionDetailsSheet(
            targetType: 'PROGRESS',
            targetId: 'library-1',
            loader: () async => const ReactionDetails(total: 0, grupos: []),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay reacciones.'), findsOneWidget);
    expect(find.byTooltip('Actualizar reacciones'), findsOneWidget);
  });

  testWidgets('una reacción mantiene el sheet compacto', (tester) async {
    await _pumpSheet(tester, _details([1]));
    final height = tester
        .getSize(find.byKey(const ValueKey('reaction-sheet-loaded')))
        .height;
    expect(height, inInclusiveRange(220, 280));
  });

  testWidgets('cinco reacciones ajustan la altura al contenido', (
    tester,
  ) async {
    await _pumpSheet(tester, _details([5]));
    final height = tester
        .getSize(find.byKey(const ValueKey('reaction-sheet-loaded')))
        .height;
    expect(height, inInclusiveRange(400, 470));
    expect(height, lessThan(800 * .68));
  });

  testWidgets('una lista larga respeta el máximo y permite scroll', (
    tester,
  ) async {
    await _pumpSheet(tester, _details([12]));
    final height = tester
        .getSize(find.byKey(const ValueKey('reaction-sheet-loaded')))
        .height;
    expect(height, closeTo(800 * .68, .1));
    final lists = find.byType(ListView);
    expect(lists, findsWidgets);
    final scrollable = find.descendant(
      of: lists.first,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    expect(
      tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      greaterThan(0),
    );
  });

  testWidgets('cambiar a un emoji minoritario reduce la altura sin overflow', (
    tester,
  ) async {
    await _pumpSheet(tester, _details([5, 1]));
    final before = tester
        .getSize(find.byKey(const ValueKey('reaction-sheet-loaded')))
        .height;
    await tester.tap(find.text('👏 1'));
    await tester.pumpAndSettle();
    final after = tester
        .getSize(find.byKey(const ValueKey('reaction-sheet-loaded')))
        .height;
    expect(after, lessThan(before));
    expect(after, inInclusiveRange(220, 280));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pantalla pequeña y texto ampliado no producen overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpSheet(
      tester,
      _details([8]),
      textScale: 1.8,
      mediaSize: const Size(320, 420),
    );
    final height = tester
        .getSize(find.byKey(const ValueKey('reaction-sheet-loaded')))
        .height;
    expect(height, lessThanOrEqualTo(420 * .68));
    expect(find.text('Reacciones'), findsOneWidget);
    expect(find.text('Todas 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSheet(
  WidgetTester tester,
  ReactionDetails details, {
  double textScale = 1,
  Size mediaSize = const Size(800, 800),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(size: mediaSize, textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: ReactionDetailsSheet(
          targetType: 'COMMENT',
          targetId: 'adaptive',
          loader: () async => details,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ReactionDetails _details(List<int> groupSizes) => ReactionDetails(
  total: groupSizes.fold(0, (total, size) => total + size),
  grupos: List.generate(groupSizes.length, (groupIndex) {
    final reaction = groupIndex == 0 ? 'LIKE' : 'CLAP';
    return ReactionGroup(
      reaccion: reaction,
      usuarios: List.generate(
        groupSizes[groupIndex],
        (userIndex) => ReactionUser(
          id: '$groupIndex-$userIndex',
          nombre: 'Persona $groupIndex-$userIndex',
          avatarUrl: '',
          esTu: false,
          fecha: DateTime.utc(2026, 8, 1, 10, userIndex),
        ),
      ),
    );
  }),
);
