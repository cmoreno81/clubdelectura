import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:club_lectura_app/pages/liga_page.dart';

void main() {
  Future<int> pulsar(WidgetTester tester, int ocultos) async {
    var toques = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HuecoTablaLiga(ocultos: ocultos, onTap: () => toques++),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('liga-ver-completa')));
    return toques;
  }

  testWidgets(
    'los puntos suspensivos se pulsan y dicen cuántos puestos faltan',
    (tester) async {
      expect(await pulsar(tester, 3), 1);
      expect(find.text('Ver los 3 puestos que faltan'), findsOneWidget);
    },
  );

  testWidgets('en singular cuando falta un solo puesto', (tester) async {
    await pulsar(tester, 1);
    expect(find.text('Ver el puesto que falta'), findsOneWidget);
  });
}
