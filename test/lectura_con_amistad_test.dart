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
    expect(find.text('Elige un amigo'), findsOneWidget);

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

  testWidgets(
    'en el perfil de una amistad solo salen sus lecturas, o un espacio vacío',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const datos = LecturasAmistadesData(
        lecturas: [
          LecturaConAmistad(
            clubId: 'c1',
            bookId: 'b1',
            libro: 'Libro de Lucía',
            con: 'Lucía',
          ),
          LecturaConAmistad(
            clubId: 'c2',
            bookId: 'b2',
            libro: 'Libro de Marta',
            con: 'Marta',
          ),
        ],
      );
      Widget con(String nombre) => MaterialApp(
        key: UniqueKey(),
        home: Scaffold(
          body: LecturasConAmistadesSeccion(
            cargar: () async => datos,
            soloCon: nombre,
            titulo: 'Lecturas abiertas con $nombre 📖',
            textoVacio: 'Todavía no leéis nada a la vez.',
          ),
        ),
      );

      await tester.pumpWidget(con('Lucía'));
      await tester.pumpAndSettle();
      expect(find.text('Lecturas abiertas con Lucía 📖'), findsOneWidget);
      expect(find.text('Libro de Lucía'), findsOneWidget);
      expect(find.text('Libro de Marta'), findsNothing);

      await tester.pumpWidget(con('Noa'));
      await tester.pumpAndSettle();
      expect(find.text('Todavía no leéis nada a la vez.'), findsOneWidget);
    },
  );

  test('las lecturas se separan en curso y terminadas', () {
    final d = LecturasAmistadesData.fromJson({
      'lecturas': [
        {'clubId': 'a', 'libro': 'A', 'con': 'X', 'terminada': false},
        {'clubId': 'b', 'libro': 'B', 'con': 'X', 'terminada': true},
        {'clubId': 'c', 'libro': 'C', 'con': 'Y', 'esperando': true},
      ],
    });
    expect(d.enCurso.map((l) => l.libro), ['A', 'C']);
    expect(d.terminadas.map((l) => l.libro), ['B']);
  });

  testWidgets(
    'las terminadas van aparte, plegadas, y se pueden volver a abrir',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      String? abierta;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LecturasConAmistadesSeccion(
                cargar: () async => const LecturasAmistadesData(
                  lecturas: [
                    LecturaConAmistad(
                      clubId: 'c1',
                      bookId: 'b1',
                      libro: 'En marcha',
                      con: 'Lucía',
                    ),
                    LecturaConAmistad(
                      clubId: 'c2',
                      bookId: 'b2',
                      libro: 'Ya leído',
                      con: 'Marta',
                      terminada: true,
                    ),
                  ],
                ),
                abrir: (clubId, libro) async => abierta = clubId,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('En marcha'), findsOneWidget);
      expect(find.text('Terminadas ✓ (1)'), findsOneWidget);
      expect(find.text('Ya leído'), findsNothing);

      await tester.tap(find.text('Terminadas ✓ (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Ya leído'), findsOneWidget);
      expect(find.text('Terminada ✓ · Con Marta'), findsOneWidget);
      await tester.tap(find.text('Ya leído'));
      await tester.pump();
      expect(abierta, 'c2');
    },
  );

  testWidgets(
    'salir o eliminar piden confirmación; eliminar solo lo ofrece quien la abrió',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final llamadas = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LecturasConAmistadesSeccion(
                cargar: () async => const LecturasAmistadesData(
                  lecturas: [
                    LecturaConAmistad(
                      clubId: 'c1',
                      bookId: 'b1',
                      libro: 'Mía',
                      con: 'Lucía',
                      esDuena: true,
                    ),
                    LecturaConAmistad(
                      clubId: 'c2',
                      bookId: 'b2',
                      libro: 'De Marta',
                      con: 'Marta',
                      salio: true,
                    ),
                  ],
                ),
                salir: (id, eliminar) async {
                  llamadas.add('$id:$eliminar');
                  return const ResultadoAmistad(ok: true);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Marta ha salido · puedes seguir consultándola'),
        findsOneWidget,
      );

      // La de Marta: solo «Salir».
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();
      expect(find.text('Salir de la lectura'), findsOneWidget);
      expect(find.text('Eliminar para las dos'), findsNothing);
      await tester.tapAt(const Offset(5, 5)); // cierra el menú
      await tester.pumpAndSettle();

      // La mía: eliminar con confirmación.
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar para las dos'));
      await tester.pumpAndSettle();
      expect(llamadas, isEmpty); // aún sin confirmar
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(llamadas, ['c1:true']);
    },
  );
}
