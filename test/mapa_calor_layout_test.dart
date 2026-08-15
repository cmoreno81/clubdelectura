import 'package:club_lectura_app/widgets/common/mapa_calor_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final days in [0, 1, 31]) {
    testWidgets('$days días mantiene cabecera y leyenda visibles a 320 px', (
      tester,
    ) async {
      await _pumpMap(tester, width: 320, activeDays: days);

      expect(find.text('Actividad de lectura 2026'), findsOneWidget);
      expect(
        find.text(
          '$days ${days == 1 ? 'día leído' : 'días leídos'}',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('Sin actividad'), findsOneWidget);
      expect(find.text('Muy activa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ancho inferior usa scroll horizontal real para la cuadrícula', (
    tester,
  ) async {
    await _pumpMap(tester, width: 150, activeDays: 31);

    final horizontal = tester
        .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .firstWhere((view) => view.scrollDirection == Axis.horizontal);
    expect(horizontal.physics, isA<ClampingScrollPhysics>());
    expect(find.text('Sin actividad'), findsOneWidget);
    expect(find.text('Muy activa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('texto ampliado coloca la píldora debajo sin overflow', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      width: 260,
      activeDays: 1,
      textScaler: const TextScaler.linear(2),
    );

    final titleBottom = tester
        .getBottomLeft(find.text('Actividad de lectura 2026'))
        .dy;
    final pillTop = tester
        .getTopLeft(find.text('1 día leído', findRichText: true))
        .dy;
    expect(pillTop, greaterThanOrEqualTo(titleBottom));
    expect(find.text('Sin actividad'), findsOneWidget);
    expect(find.text('Muy activa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la cuadrícula no desplaza cuando cabe exactamente', (
    tester,
  ) async {
    await _pumpMap(tester, width: 320, activeDays: 0);

    final horizontal = tester
        .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
        .firstWhere((view) => view.scrollDirection == Axis.horizontal);
    expect(horizontal.physics, isA<NeverScrollableScrollPhysics>());
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpMap(
  WidgetTester tester, {
  required double width,
  required int activeDays,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: MapaCalorWidget(
                  anio: 2026,
                  loadData: (_) async => {
                    'days': const <Map<String, dynamic>>[],
                    'totalActiveDays': activeDays,
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
