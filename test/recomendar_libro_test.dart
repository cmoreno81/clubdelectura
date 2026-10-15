import 'package:club_lectura_app/models/amistad.dart';
import 'package:club_lectura_app/models/libro.dart';
import 'package:club_lectura_app/widgets/amistades/recomendar_libro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _datos = AmistadesData(
  miCodigo: 'ABCD-2345',
  amistades: [
    PersonaAmistad(nombre: 'Lucía'),
    PersonaAmistad(nombre: 'Marta'),
  ],
);

Widget _hoja({
  Key? key,
  required Future<AmistadesData> Function() cargar,
  required Future<ResultadoAmistad> Function({
    required String bookId,
    required List<String> usuarios,
    String mensaje,
    bool juntas,
  })
  enviar,
}) => MaterialApp(
  key: key,
  home: Scaffold(
    body: RecomendarLibroSheet(
      bookId: 'b1',
      titulo: 'Yesteryear',
      cargar: cargar,
      enviar: enviar,
    ),
  ),
);

void main() {
  testWidgets('elige amistades, escribe un mensaje y envía', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    List<String>? enviados;
    String? textoEnviado;
    bool? juntasEnviado;
    await tester.pumpWidget(
      _hoja(
        cargar: () async => _datos,
        enviar:
            ({
              required bookId,
              required usuarios,
              String mensaje = '',
              bool juntas = false,
            }) async {
              enviados = usuarios;
              textoEnviado = mensaje;
              juntasEnviado = juntas;
              return const ResultadoAmistad(ok: true, enviadas: 1);
            },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Elige a alguien'), findsOneWidget);

    await tester.tap(find.text('Marta'));
    await tester.pump();
    expect(find.text('Enviar a 1 amigo'), findsOneWidget);
    await tester.tap(find.text('Enviar a 1 amigo'));
    await tester.pump();
    expect(enviados, ['Marta']);
    expect(textoEnviado, '');
    expect(juntasEnviado, false);
  });

  testWidgets('sin amistades invita a buscar y si falla lo dice', (
    tester,
  ) async {
    Future<ResultadoAmistad> nada({
      required String bookId,
      required List<String> usuarios,
      String mensaje = '',
      bool juntas = false,
    }) async => const ResultadoAmistad(ok: false);
    await tester.pumpWidget(
      _hoja(
        cargar: () async => const AmistadesData(miCodigo: 'X'),
        enviar: nada,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Buscar o invitar amigos'), findsOneWidget);

    await tester.pumpWidget(
      _hoja(
        key: UniqueKey(),
        cargar: () async => throw Exception('servidor antiguo'),
        enviar: nada,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No se han podido cargar'), findsOneWidget);
  });

  testWidgets(
    'desde el perfil de una amiga: eliges uno de tus libros (terminados primero) y se abre la hoja para ella',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => mostrarRecomendarAUnaAmiga(
                  context,
                  nombre: 'Marta',
                  cargarLibros: () async => [
                    Libro.fromJson({
                      'bookId': 'b1',
                      'libro': 'Zorro',
                      'estado': 'PENDIENTE',
                    }),
                    Libro.fromJson({
                      'bookId': 'b2',
                      'libro': 'Babel',
                      'estado': 'FINALIZADO',
                      'valoracion': '4',
                    }),
                    Libro.fromJson({
                      'bookId': 'b3',
                      'libro': 'Dune',
                      'estado': 'FINALIZADO',
                      'valoracion': '5',
                    }),
                    Libro.fromJson({
                      'bookId': 'b4',
                      'libro': 'Ahora leo',
                      'estado': 'LEYENDO',
                    }),
                  ],
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('¿Qué libro le recomiendas a Marta?'), findsOneWidget);
      // Leídos de mayor a menor nota, después los pendientes; lo demás no sale.
      final dune = tester
          .getTopLeft(find.byKey(const Key('recomendar-libro-b3')))
          .dx;
      final babel = tester
          .getTopLeft(find.byKey(const Key('recomendar-libro-b2')))
          .dx;
      final zorro = tester
          .getTopLeft(find.byKey(const Key('recomendar-libro-b1')))
          .dx;
      expect(dune < babel && babel < zorro, isTrue);
      expect(find.byKey(const Key('recomendar-libro-b4')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('recomendar-buscar-libro')),
        'zor',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recomendar-libro-b2')), findsNothing);

      await tester.tap(find.byKey(const Key('recomendar-libro-b1')));
      await tester.pumpAndSettle();
      expect(find.text('Recomendar a un amigo'), findsOneWidget);
      expect(find.textContaining('«Zorro»'), findsOneWidget);
    },
  );
}
