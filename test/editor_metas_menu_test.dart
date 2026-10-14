import 'package:club_lectura_app/models/configuracion_lectura.dart';
import 'package:club_lectura_app/widgets/lectura/editor_metas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'el desplegable de capítulos no ocupa toda la pantalla con muchos capítulos',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EditorMetas(
                metas: const [MetaLectura(capitulo: 5, fecha: '2026-10-25')],
                capitulos: 60,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();

      // La lista del menú no pasa de ~260 px aunque haya 60 capítulos.
      final menu = find
          .byType(Scrollable)
          .evaluate()
          .map((e) => e.renderObject)
          .whereType<RenderBox>();
      final alturas = menu.map((r) => r.size.height).toList();
      expect(alturas.any((h) => h <= 270), isTrue, reason: '$alturas');
      expect(find.text('60'), findsNothing); // no caben todos a la vez
      expect(find.text('5'), findsWidgets);
    },
  );
}
