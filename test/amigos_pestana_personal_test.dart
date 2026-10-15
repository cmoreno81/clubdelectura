import 'package:club_lectura_app/models/amistad.dart';
import 'package:club_lectura_app/pages/amistades_page.dart';
import 'package:club_lectura_app/widgets/amistades/panel_amigos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Amigos como pestaña: sin flecha atrás y con el resumen arriba', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AmistadesPage(
          embebida: true,
          cargar: () async => const AmistadesData(
            miCodigo: 'ABCD-2345',
            amistades: [PersonaAmistad(nombre: 'Marta')],
            recibidas: [
              PersonaAmistad(nombre: 'Sara'),
              PersonaAmistad(nombre: 'Leo'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('amistades-resumen')), findsOneWidget);
    expect(find.text('por responder'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('ABCD-2345'), findsOneWidget);
  });

  testWidgets(
    'Amigos desde Inicio (cuentas con club) enseña el mismo resumen',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AmistadesPage(cargar: () async => const AmistadesData()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('amistades-resumen')), findsOneWidget);
    },
  );

  testWidgets(
    'el feed cuenta qué hacen los amigos, con nota y reseña sin spoilers',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FeedAmistades(
                cargar: () async => [
                  FeedAmistad(
                    tipo: 'TERMINO',
                    nombre: 'Julia',
                    libraryId: 'l1',
                    bookId: 'b1',
                    titulo: 'Mañana, y mañana',
                    valoracion: 4.5,
                    resena: 'Me ha roto el corazón',
                    comentarios: 2,
                    fecha: DateTime.now().subtract(const Duration(days: 3)),
                  ),
                  FeedAmistad(
                    tipo: 'EMPEZO',
                    nombre: 'Irene',
                    libraryId: 'l2',
                    bookId: 'b2',
                    titulo: 'Yellowface',
                    fecha: DateTime.now().subtract(const Duration(days: 1)),
                  ),
                  const FeedAmistad(
                    tipo: 'TERMINO',
                    nombre: 'Noa',
                    libraryId: 'l3',
                    bookId: 'b3',
                    titulo: 'Babel',
                    contieneSpoilers: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Julia ha terminado'), findsOneWidget);
      expect(find.text('Irene ha empezado'), findsOneWidget);
      expect(find.text('«Me ha roto el corazón»'), findsOneWidget);
      expect(find.text('hace 3 días'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
      expect(
        find.text('Su reseña tiene spoilers: ábrela desde el libro.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('feed-comentarios')), findsNWidgets(3));
    },
  );

  testWidgets('sin actividad no sale el feed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FeedAmistades(cargar: () async => [])),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('amigos-feed')), findsNothing);
  });

  testWidgets('«Ideas para regalar» salta lo ya reservado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IdeasParaRegalar(
            cargar: () async => [
              (
                'Marta',
                const [
                  LibroDeAmistad(bookId: 'a', titulo: 'Babel'),
                  LibroDeAmistad(bookId: 'b', titulo: 'Dune', reservado: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('amigos-ideas-regalo')), findsOneWidget);
    expect(find.text('Para Marta'), findsOneWidget);
  });

  testWidgets('sin deseos libres no sale «Ideas para regalar»', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: IdeasParaRegalar(cargar: () async => [])),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('amigos-ideas-regalo')), findsNothing);
  });

  testWidgets(
    'los cuadros del resumen llevan a su sección o avisan si está vacía',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AmistadesPage(
            embebida: true,
            cargar: () async => AmistadesData(
              miCodigo: 'ABCD-2345',
              amistades: [
                for (var i = 0; i < 12; i++) PersonaAmistad(nombre: 'Amiga $i'),
              ],
              recibidas: const [PersonaAmistad(nombre: 'Sara')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vacía: avisa.
      await tester.tap(find.byKey(const Key('resumen-enviadas')));
      await tester.pump();
      expect(find.text('No tienes solicitudes enviadas.'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Con solicitudes: baja hasta «Solicitudes recibidas».
      await tester.tap(find.byKey(const Key('resumen-por responder')));
      await tester.pumpAndSettle();
      expect(find.text('Solicitudes recibidas (1)'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Solicitudes recibidas (1)')).dy,
        lessThan(300),
      );
    },
  );

  testWidgets(
    'afinidad: lista por libros en común con porcentaje y texto claro',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AfinidadAmigosSeccion(
              cargar: () async => const [
                AfinidadAmistad(
                  nombre: 'Marta',
                  enComun: 14,
                  afinidad: 62,
                  generos: ['Fantasía', 'Romance'],
                  notasParecidas: true,
                ),
                AfinidadAmistad(nombre: 'Irene', enComun: 1, afinidad: 5),
                AfinidadAmistad(nombre: 'Nadie', enComun: 0),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Coincidís en 14 libros · Fantasía, Romance · Puntuáis parecido',
        ),
        findsOneWidget,
      );
      expect(find.text('62%'), findsOneWidget);
      expect(find.text('Coincidís en 1 libro'), findsOneWidget);
      expect(find.text('Nadie'), findsNothing);
    },
  );

  testWidgets('«Tus amigos y este libro» enseña estado y nota; vacío no sale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmigosDelLibroSeccion(
            bookId: 'b1',
            cargar: (_) async => const [
              AmigoDelLibro(nombre: 'Marta', estado: 'LEYENDO', progreso: 40),
              AmigoDelLibro(
                nombre: 'Julia',
                estado: 'TERMINADO',
                valoracion: 4.5,
              ),
              AmigoDelLibro(nombre: 'Noa', estado: 'PENDIENTE'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lo está leyendo · 40%'), findsOneWidget);
    expect(find.text('Lo ha leído'), findsOneWidget);
    expect(find.text('Lo tiene pendiente'), findsOneWidget);
    expect(find.text(' 4.5'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmigosDelLibroSeccion(
            key: UniqueKey(),
            bookId: 'b2',
            cargar: (_) async => [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('amigos-del-libro')), findsNothing);
  });

  testWidgets(
    'resumen semanal: libros, el más leído y quién más; vacío no sale',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResumenSemanalAmigosCard(
              cargar: () async => const ResumenSemanalAmigos(
                terminados: 7,
                personas: 2,
                libroTitulo: 'Babel',
                libroVeces: 2,
                quienMas: 'Bea',
                quienMasTotal: 5,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('7 libros terminados'), findsOneWidget);
      expect(find.text('El más leído: «Babel» (2)'), findsOneWidget);
      expect(find.text('Quien más: Bea (5)'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResumenSemanalAmigosCard(
              key: UniqueKey(),
              cargar: () async => const ResumenSemanalAmigos(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('amigos-resumen-semanal')), findsNothing);
    },
  );
}
