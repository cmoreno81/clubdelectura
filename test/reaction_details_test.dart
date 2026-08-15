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
}
