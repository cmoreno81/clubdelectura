import 'package:club_lectura_app/models/perfil_usuario.dart';
import 'package:club_lectura_app/widgets/perfil/perfil_saga_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: PerfilSagaCard(
                        key: const Key('corta'),
                        saga: _saga('Corta', 2),
                        rellenarAlto: true,
                      ),
                    ),
                    Expanded(
                      child: PerfilSagaCard(
                        key: const Key('larga'),
                        saga: _saga('Larga', 14),
                        rellenarAlto: true,
                      ),
                    ),
                  ],
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
}
