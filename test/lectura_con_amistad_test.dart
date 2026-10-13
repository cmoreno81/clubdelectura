import 'package:club_lectura_app/models/amistad.dart';
import 'package:club_lectura_app/widgets/amistades/lectura_con_amistad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _datos = AmistadesData(
  miCodigo: 'X',
  amistades: [
    PersonaAmistad(nombre: 'Lucía'),
    PersonaAmistad(nombre: 'Marta'),
  ],
);

void main() {
  test('las lecturas a la vez del servidor se leen', () {
    final d = LecturasAmistadesData.fromJson({
      'recibidas': [
        {'clubId': 'c1', 'bookId': 'b1', 'libro': 'Yesteryear', 'de': 'Lucía'},
      ],
      'lecturas': [
        {'clubId': 'c2', 'libro': 'Otro', 'con': 'Marta', 'esperando': true},
      ],
    });
    expect(d.vacia, isFalse);
    expect(d.recibidas.single.de, 'Lucía');
    expect(d.lecturas.single.esperando, isTrue);
    expect(const LecturasAmistadesData().vacia, isTrue);
  });

  testWidgets('elegir una amistad y empezar devuelve la lectura creada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? pedido;
    ResultadoAmistad? devuelto;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  devuelto = await showModalBottomSheet<ResultadoAmistad>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => LeerConAmistadSheet(
                      bookId: 'b1',
                      titulo: 'Yesteryear',
                      cargar: () async => _datos,
                      crear: ({required bookId, required nombre}) async {
                        pedido = '$bookId:$nombre';
                        return const ResultadoAmistad(
                          ok: true,
                          clubId: 'c9',
                          libro: 'Yesteryear',
                        );
                      },
                    ),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Elige una amistad'), findsOneWidget);

    await tester.tap(find.text('Marta'));
    await tester.pump();
    expect(find.text('Invitar a Marta'), findsOneWidget);
    await tester.tap(find.text('Invitar a Marta'));
    await tester.pumpAndSettle();
    expect(pedido, 'b1:Marta');
    expect(devuelto?.clubId, 'c9');
  });

  testWidgets('la sección enseña invitaciones y lecturas, y responde', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var cargas = 0;
    String? respondida;
    String? abierta;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LecturasConAmistadesSeccion(
              cargar: () async {
                cargas++;
                return const LecturasAmistadesData(
                  recibidas: [
                    InvitacionLecturaAmistad(
                      clubId: 'c1',
                      bookId: 'b1',
                      libro: 'Yesteryear',
                      de: 'Lucía',
                    ),
                  ],
                  lecturas: [
                    LecturaConAmistad(
                      clubId: 'c2',
                      bookId: 'b2',
                      libro: 'Otro libro',
                      con: 'Marta',
                      esperando: true,
                    ),
                  ],
                );
              },
              responder: (clubId, aceptar) async {
                respondida = '$clubId:$aceptar';
                return const ResultadoAmistad(ok: true);
              },
              abrir: (clubId, libro) async => abierta = '$clubId:$libro',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lecturas a la vez 📖'), findsOneWidget);
    expect(
      find.text('Lucía te propone leer «Yesteryear» a la vez'),
      findsOneWidget,
    );
    expect(find.text('Con Marta · esperando su respuesta'), findsOneWidget);

    await tester.tap(find.text('Otro libro'));
    await tester.pump();
    expect(abierta, 'c2:Otro libro');

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    expect(respondida, 'c1:true');
    expect(cargas, 2);
    expect(abierta, 'c1:Yesteryear');
  });

  testWidgets('sin datos o con servidor antiguo no ocupa nada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LecturasConAmistadesSeccion(
            cargar: () async => throw Exception('servidor antiguo'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lecturas a la vez 📖'), findsNothing);
  });
}
