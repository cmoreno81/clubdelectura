import 'package:club_lectura_app/models/perfil_usuario.dart';
import 'package:club_lectura_app/widgets/common/fila_igual_altura.dart';
import 'package:club_lectura_app/widgets/perfil/perfil_saga_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

PerfilSaga _saga(String nombre, int tomos) {
  final volumenes = [
    for (var i = 1; i <= tomos; i++)
      PerfilSagaVolumen(
        bookId: '$nombre$i',
        titulo: '$nombre $i',
        numero: '$i',
        posicion: i,
        coverUrl: '',
        estado: i == 1 ? 'LEIDO' : 'PENDIENTE',
      ),
  ];
  return PerfilSaga(
    id: nombre,
    nombre: nombre,
    autor: 'Autora',
    leidos: 1,
    totalConocidos: tomos,
    totalSaga: tomos,
    estado: 'EN_CURSO',
    estadoEditorial: 'COMPLETED',
    volumenes: volumenes,
    siguiente: volumenes[1],
  );
}

void main() {
  testWidgets(
    'en una fila de dos, una saga corta y otra larga miden lo mismo y «Siguiente» queda abajo',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilaIgualAltura(
                separacion: 0,
                izquierda: PerfilSagaCard(
                  key: const Key('corta'),
                  saga: _saga('Corta', 2),
                  rellenarAlto: true,
                ),
                derecha: PerfilSagaCard(
                  key: const Key('larga'),
                  saga: _saga('Larga', 14),
                  rellenarAlto: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final corta = tester.getRect(find.byKey(const Key('corta')));
      final larga = tester.getRect(find.byKey(const Key('larga')));
      expect(corta.height, larga.height);

      final siguientes = find.text('Siguiente para continuar');
      expect(siguientes, findsNWidgets(2));
      final y0 = tester.getBottomLeft(siguientes.at(0)).dy;
      final y1 = tester.getBottomLeft(siguientes.at(1)).dy;
      expect((y0 - y1).abs(), lessThan(1), reason: 'alineados abajo');
    },
  );

  testWidgets('sin rellenarAlto la tarjeta mide lo que su contenido', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PerfilSagaCard(saga: _saga('Corta', 2)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Siguiente para continuar'), findsOneWidget);
  });

  testWidgets(
    'reordenar los tomos de una saga en la fila no la hace desaparecer',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FilaIgualAltura(
                separacion: 16,
                izquierda: PerfilSagaCard(
                  saga: _saga('Corta', 3),
                  rellenarAlto: true,
                  onReorderVolumes: (_) async {},
                ),
                derecha: PerfilSagaCard(
                  saga: _saga('Larga', 9),
                  rellenarAlto: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Reordenar volúmenes'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Arrastra los tomos'), findsOneWidget);
      final izq = tester.getRect(find.text('Corta').first);
      expect(izq.height, greaterThan(0));
      // Las dos tarjetas siguen midiendo lo mismo.
      final cards = find.byType(PerfilSagaCard);
      expect(
        tester.getSize(cards.at(0)).height,
        tester.getSize(cards.at(1)).height,
      );
    },
  );

  testWidgets('«Completar saga» solo sale si falta algún tomo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Widget tarjeta(PerfilSaga saga) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PerfilSagaCard(saga: saga, onCompleteCatalog: () {}),
        ),
      ),
    );
    // Todos los tomos en la biblioteca: no hay nada que completar.
    final completa = PerfilSaga(
      id: 'c',
      nombre: 'Completa',
      autor: 'A',
      leidos: 3,
      totalConocidos: 3,
      totalSaga: 3,
      estado: 'COMPLETADA',
      estadoEditorial: 'COMPLETED',
      volumenes: [
        for (var i = 1; i <= 3; i++)
          PerfilSagaVolumen(
            bookId: 'c$i',
            titulo: 'C $i',
            numero: '$i',
            posicion: i,
            coverUrl: '',
            estado: 'LEIDO',
          ),
      ],
    );
    await tester.pumpWidget(tarjeta(completa));
    await tester.pumpAndSettle();
    expect(find.text('Completar saga'), findsNothing);

    // Falta un tomo (el 3 no está en la biblioteca): el botón sale.
    final incompleta = PerfilSaga(
      id: 'i',
      nombre: 'Incompleta',
      autor: 'A',
      leidos: 2,
      totalConocidos: 2,
      totalSaga: 3,
      estado: 'EN_CURSO',
      estadoEditorial: 'ONGOING',
      volumenes: [
        for (var i = 1; i <= 2; i++)
          PerfilSagaVolumen(
            bookId: 'i$i',
            titulo: 'I $i',
            numero: '$i',
            posicion: i,
            coverUrl: '',
            estado: 'LEIDO',
          ),
      ],
    );
    await tester.pumpWidget(tarjeta(incompleta));
    await tester.pumpAndSettle();
    expect(find.text('Completar saga'), findsOneWidget);
  });
}
