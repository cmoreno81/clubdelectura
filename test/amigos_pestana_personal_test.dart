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

  testWidgets('Amigos suelto (desde Inicio) no enseña el resumen de pestaña', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AmistadesPage(cargar: () async => const AmistadesData()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('amistades-resumen')), findsNothing);
  });

  testWidgets(
    '«Lo último» enseña lo que han terminado, lo más reciente primero',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoUltimoAmistades(
              cargar: () async => [
                ActividadAmistad(
                  tipo: 'TERMINADO',
                  nombre: 'Julia',
                  bookId: 'b1',
                  titulo: 'Mañana, y mañana',
                  valoracion: 4.5,
                  fecha: DateTime.now().subtract(const Duration(days: 3)),
                ),
                ActividadAmistad(
                  tipo: 'TERMINADO',
                  nombre: 'Irene',
                  bookId: 'b2',
                  titulo: 'Yellowface',
                  fecha: DateTime.now().subtract(const Duration(days: 1)),
                ),
                const ActividadAmistad(
                  tipo: 'LEYENDO',
                  nombre: 'Marta',
                  bookId: 'b3',
                  titulo: 'Fourth Wing',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Irene ha terminado'), findsOneWidget);
      expect(find.text('Julia ha terminado'), findsOneWidget);
      expect(find.text('Marta ha terminado'), findsNothing);
      expect(find.text('ayer'), findsOneWidget);
      expect(find.text('hace 3 días'), findsOneWidget);
      expect(find.text(' 4.5'), findsOneWidget);
    },
  );

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
}
