import 'dart:async';

import 'package:club_lectura_app/widgets/tablet/detalle_lateral.dart';
import 'package:club_lectura_app/widgets/tablet/marco_tablet.dart';
import 'package:club_lectura_app/widgets/tablet/shell_navegacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Size tamano, {Widget? contenido}) => MediaQuery(
  data: MediaQueryData(size: tamano),
  child: MaterialApp(
    home: MarcoTablet(
      child:
          contenido ?? const Scaffold(body: Center(child: Text('contenido'))),
    ),
  ),
);

void main() {
  tearDown(() {
    ShellNavegacion.instance.liberar('prueba');
  });

  test('esTablet: solo con lado corto >= 600', () {
    expect(esTablet(const Size(390, 844)), isFalse);
    expect(
      esTablet(const Size(932, 430)),
      isFalse,
      reason: 'iPhone en horizontal',
    );
    expect(esTablet(const Size(820, 1180)), isTrue);
    expect(esTablet(const Size(1032, 1376)), isTrue);
    expect(esTablet(const Size(600, 960)), isTrue, reason: '7" en vertical');
    expect(
      esTablet(const Size(520, 900)),
      isFalse,
      reason: 'Split View estrecho',
    );
    expect(barraCompacta(const Size(600, 960)), isTrue);
    expect(barraCompacta(const Size(820, 1180)), isFalse);
  });

  testWidgets('en móvil no se añade nada', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    ShellNavegacion.instance.registrar('prueba', alSeleccionar: (_) {});
    await tester.pumpWidget(_app(const Size(390, 844)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('barra-lateral')), findsNothing);
    expect(find.text('contenido'), findsOneWidget);
  });

  testWidgets('en tablet sin sesión: columna estrecha y sin barra lateral', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1032, 1376);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const Size(1032, 1376)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('barra-lateral')), findsNothing);
    expect(tester.getSize(find.byType(Scaffold)).width, 560);
  });

  testWidgets(
    'en tablet con sesión: barra lateral, columna y toques reenviados',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1032, 1376);
      addTearDown(tester.view.reset);
      final pulsados = <int>[];
      ShellNavegacion.instance.registrar('prueba', alSeleccionar: pulsados.add);
      ShellNavegacion.instance.actualizar(seleccion: 0, tieneClub: true);
      await tester.pumpWidget(_app(const Size(1032, 1376)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('barra-lateral')), findsOneWidget);
      expect(find.text('Mi club'), findsOneWidget);
      expect(tester.getSize(find.byType(Scaffold)).width, 784);

      await tester.tap(find.byKey(const Key('barra-lateral-1')));
      await tester.tap(find.byKey(const Key('barra-lateral-4')));
      expect(pulsados, [1, 4]);

      ShellNavegacion.instance.marcarSeccion('prueba', 3);
      await tester.pumpAndSettle();
      expect(ShellNavegacion.instance.seleccion, 3);
      ShellNavegacion.instance.soltarSeccion('prueba');
      await tester.pumpAndSettle();
      expect(ShellNavegacion.instance.seleccion, 0);
    },
  );

  group('panel de detalle', () {
    tearDown(() => DetalleLateral.instance.cerrar());

    testWidgets('iPad ancho: la ficha se abre en el panel y la X lo cierra', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1376, 1032);
      addTearDown(tester.view.reset);
      ShellNavegacion.instance.registrar('prueba', alSeleccionar: (_) {});
      await tester.pumpWidget(_app(const Size(1376, 1032)));
      await tester.pumpAndSettle();
      expect(DetalleLateral.instance.disponible, isTrue);

      final contexto = tester.element(find.text('contenido'));
      unawaited(
        empujarDetalle<void>(
          contexto,
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('ficha')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('panel-detalle')), findsOneWidget);
      expect(find.text('ficha'), findsOneWidget);
      expect(
        find.text('contenido'),
        findsOneWidget,
        reason: 'la lista sigue a la vista',
      );

      await tester.tap(find.byKey(const Key('panel-detalle-cerrar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('panel-detalle')), findsNothing);
      expect(find.text('ficha'), findsNothing);
    });

    testWidgets(
      'iPad estrecho: no hay panel y la ficha se apila como siempre',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1032, 1376);
        addTearDown(tester.view.reset);
        ShellNavegacion.instance.registrar('prueba', alSeleccionar: (_) {});
        await tester.pumpWidget(_app(const Size(1032, 1376)));
        await tester.pumpAndSettle();
        expect(DetalleLateral.instance.disponible, isFalse);

        final contexto = tester.element(find.text('contenido'));
        unawaited(
          empujarDetalle<void>(
            contexto,
            MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('ficha')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('panel-detalle')), findsNothing);
        expect(find.text('ficha'), findsOneWidget);
      },
    );
  });

  testWidgets('arrastrar en los márgenes de la columna desplaza la lista', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1376, 1032);
    addTearDown(tester.view.reset);
    ShellNavegacion.instance.registrar('prueba', alSeleccionar: (_) {});
    final controlador = ScrollController();
    addTearDown(controlador.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MarcoTablet(child: child!),
        home: Scaffold(
          body: ListView(
            controller: controlador,
            // Como las pantallas de la app: la lista tiene relleno a los lados,
            // así que en el borde de la columna no hay ninguna fila debajo.
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (var i = 0; i < 60; i++)
                SizedBox(height: 80, child: Text('fila $i')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controlador.offset, 0);
    // La columna mide 820 y la zona 1128 (1376 − 248): quedan 154 por lado.
    // Un punto a 40 px de la barra lateral cae en el margen izquierdo.
    await tester.dragFrom(const Offset(248 + 40, 500), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controlador.offset, greaterThan(100));
    final tras = controlador.offset;
    await tester.dragFrom(const Offset(1370 - 40, 500), const Offset(0, 150));
    await tester.pumpAndSettle();
    expect(controlador.offset, lessThan(tras));
  });

  testWidgets(
    'los márgenes también desplazan pantallas con SingleChildScrollView y rutas apiladas',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1376, 1032);
      addTearDown(tester.view.reset);
      ShellNavegacion.instance.registrar('prueba', alSeleccionar: (_) {});
      final debajo = ScrollController();
      final encima = ScrollController();
      addTearDown(debajo.dispose);
      addTearDown(encima.dispose);
      Widget lista(ScrollController c, String t) => Scaffold(
        body: SingleChildScrollView(
          controller: c,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (var i = 0; i < 60; i++)
                SizedBox(height: 80, child: Text('$t $i')),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MarcoTablet(child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => lista(encima, 'encima'),
                      ),
                    ),
                    child: const Text('ir'),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: debajo,
                      child: Column(
                        children: [
                          for (var i = 0; i < 60; i++)
                            SizedBox(height: 80, child: Text('debajo $i')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(248 + 40, 500), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(debajo.offset, greaterThan(100));

      await tester.tap(find.text('ir'));
      await tester.pumpAndSettle();
      final antes = debajo.offset;
      await tester.dragFrom(
        const Offset(1370 - 40, 500),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(
        encima.offset,
        greaterThan(100),
        reason: 'se mueve la pantalla visible',
      );
      expect(debajo.offset, antes, reason: 'la tapada no se toca');
    },
  );
}
