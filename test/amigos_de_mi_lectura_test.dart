import 'package:club_lectura_app/models/amistad.dart';
import 'package:club_lectura_app/models/reaccion_comentario.dart';
import 'package:club_lectura_app/widgets/amistades/amigos_de_mi_lectura.dart';
import 'package:club_lectura_app/widgets/amistades/comentarios_progreso.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el resumen y las reacciones del servidor se leen', () {
    final r = ResumenAmigosLectura.fromJson({
      'libraryId': 'l1',
      'comentarios': 2,
      'totalReacciones': 1,
      'reacciones': {'THUMBS_UP': 1},
    });
    expect(r.hayAlgo, isTrue);
    expect(r.reacciones[ReaccionComentario.pulgarArriba], 1);
    expect(const ResumenAmigosLectura().hayAlgo, isFalse);

    final d = ComentariosProgresoData.fromJson({
      'soyDuena': true,
      'reacciones': {'THUMBS_UP': 1},
      'reaccionesDe': [
        {'nombre': 'Cris M.', 'reaccion': 'THUMBS_UP'},
      ],
    });
    expect(d.reaccionesDe.single.nombre, 'Cris M.');
    expect(d.reaccionesDe.single.reaccion, ReaccionComentario.pulgarArriba);
  });

  testWidgets(
    'la tarjeta enseña lo que han dejado los amigos y abre los comentarios',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AmigosDeMiLecturaCard(
              bookId: 'b1',
              titulo: 'Harry Potter',
              cargar: (_) async => const ResumenAmigosLectura(
                libraryId: 'l1',
                comentarios: 1,
                totalReacciones: 1,
                reacciones: {ReaccionComentario.pulgarArriba: 1},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tus amigos te animan'), findsOneWidget);
      expect(find.textContaining('1 comentario'), findsOneWidget);
      expect(find.textContaining('👍 1'), findsOneWidget);
    },
  );

  testWidgets('sin nada o con el servidor antiguo la tarjeta no ocupa sitio', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmigosDeMiLecturaCard(
            bookId: 'b1',
            titulo: 'X',
            cargar: (_) async => throw Exception('servidor antiguo'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tus amigos te animan'), findsNothing);
  });

  testWidgets('quien lee ve en la hoja quién ha reaccionado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComentariosProgresoSheet(
            libraryId: 'l1',
            titulo: 'Harry Potter',
            cargar: (_) async => ComentariosProgresoData.fromJson({
              'soyDuena': true,
              'reacciones': {'THUMBS_UP': 1},
              'reaccionesDe': [
                {'nombre': 'Cris M.', 'reaccion': 'THUMBS_UP'},
              ],
              'comentarios': [],
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Reacciones: 👍 Cris M.'), findsOneWidget);
  });
}
