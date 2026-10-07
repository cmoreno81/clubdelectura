import 'package:club_lectura_app/models/estanteria_pendientes.dart';
import 'package:club_lectura_app/widgets/dashboard/estanteria_pendientes_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EstanteriaPendientes _datos({
  int enEstanteria = 0,
  int leidos = 0,
  int entraron = 4,
}) => EstanteriaPendientes(
  pendientes: 10,
  tengo: enEstanteria,
  enEstanteria: enEstanteria,
  otrosFormatos: 0,
  serie: const [],
  anio: 2026,
  leidosAnio: leidos,
  entraronAnio: entraron,
);

Future<void> _pinta(WidgetTester tester, EstanteriaPendientes d) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BalanceAnualPila(datos: d)),
      ),
    );

void main() {
  testWidgets(
    'sin nada en casa ni leído se explica «Ya lo tengo», sin barras',
    (tester) async {
      await _pinta(tester, _datos());
      expect(find.textContaining('Marca «Ya lo tengo»'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  testWidgets('con libros en casa salen las dos barras y el mensaje', (
    tester,
  ) async {
    await _pinta(tester, _datos(enEstanteria: 3, leidos: 2));
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    expect(find.textContaining('te quedan 3 en casa'), findsOneWidget);
    expect(find.textContaining('nuevos este año: 4'), findsOneWidget);
    expect(find.textContaining('terminados este año'), findsOneWidget);
  });
}
