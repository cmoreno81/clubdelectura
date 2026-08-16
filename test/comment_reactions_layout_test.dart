import 'package:club_lectura_app/models/comentario_lectura.dart';
import 'package:club_lectura_app/widgets/lectura/comentario_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [600.0, 260.0]) {
    testWidgets('reacciones comparten Wrap a ${width.toInt()} px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: width < 300
                  ? const TextScaler.linear(1.4)
                  : TextScaler.noScaling,
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: ComentarioCard(
                  comentario: ComentarioLectura.fromJson(const {
                    'id': 'comment-1',
                    'usuario': 'Lector',
                    'fecha': '2026-08-15',
                    'comentario': 'Comentario',
                    'miReaccion': 'LIKE',
                    'reacciones': {'LIKE': 2, 'AGREE': 1, 'WOW': 3},
                  }),
                  usuarioActual: 'Lector',
                  onActualizar: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final actionsWrap = find.ancestor(
        of: find.text('Responder'),
        matching: find.byType(Wrap),
      );
      expect(actionsWrap, findsOneWidget);
      expect(
        find.descendant(of: actionsWrap, matching: find.byType(ActionChip)),
        findsNWidgets(3),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
