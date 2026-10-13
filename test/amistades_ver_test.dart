import 'package:club_lectura_app/models/amistad.dart';
import 'package:club_lectura_app/models/reaccion_comentario.dart';
import 'package:club_lectura_app/pages/perfil_amistad_page.dart';
import 'package:club_lectura_app/widgets/amistades/reacciones_progreso.dart';
import 'package:club_lectura_app/widgets/inicio/actividad_amistades_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LecturaAmistad _lectura({
  Map<ReaccionComentario, int> reacciones = const {},
  ReaccionComentario? mia,
}) => LecturaAmistad(
  libraryId: 'l1',
  bookId: 'b1',
  titulo: 'Entre dos tormentas',
  autor: 'Lucía Marín',
  progreso: 40,
  paginaActual: 120,
  paginasTotales: 300,
  nota: 'Me está encantando',
  reacciones: reacciones,
  miReaccion: mia,
);

void main() {
  test('el perfil de una amistad se lee con lo que comparte', () {
    final p = PerfilAmistad.fromJson({
      'nombre': 'Lucía',
      'bio': 'Leo de todo',
      'compartido': {'leyendo': true, 'biblioteca': false, 'resenas': false},
      'leyendo': [
        {
          'libraryId': 'l1',
          'bookId': 'b1',
          'titulo': 'Entre dos tormentas',
          'progreso': 40,
          'reacciones': {'LIKE': 2, 'CLAP': 1},
          'miReaccion': 'LIKE',
        },
      ],
      'terminados': [
        {'bookId': 'b2', 'titulo': 'Otro', 'valoracion': 4.5},
      ],
    });
    expect(p.compartido.biblioteca, isFalse);
    expect(p.compartido.leyendo, isTrue);
    expect(p.leyendo.single.reacciones[ReaccionComentario.meGusta], 2);
    expect(p.leyendo.single.reacciones[ReaccionComentario.aplaudir], 1);
    expect(p.leyendo.single.miReaccion, ReaccionComentario.meGusta);
    expect(p.terminados.single.valoracion, 4.5);
    expect(p.pendientes, isEmpty);
  });

  test('la actividad distingue leer de terminar', () {
    final leyendo = ActividadAmistad.fromJson({
      'tipo': 'LEYENDO',
      'nombre': 'Lucía',
      'bookId': 'b1',
      'titulo': 'X',
      'libraryId': 'l1',
      'progreso': 10,
    });
    final terminado = ActividadAmistad.fromJson({
      'tipo': 'TERMINADO',
      'nombre': 'Marta',
      'bookId': 'b2',
      'titulo': 'Y',
      'valoracion': 3,
    });
    expect(leyendo.esLectura, isTrue);
    expect(leyendo.lectura?.progreso, 10);
    expect(terminado.esLectura, isFalse);
    expect(terminado.lectura, isNull);
    expect(terminado.valoracion, 3.0);
  });

  testWidgets('el perfil enseña lo que lee y avisa de lo que no comparte', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: PerfilAmistadPage(
          nombre: 'Lucía',
          cargar: (_) async => PerfilAmistad(
            nombre: 'Lucía',
            bio: 'Leo de todo',
            compartido: const PrivacidadAmistades(
              leyendo: true,
              biblioteca: false,
              resenas: false,
            ),
            leyendo: [_lectura()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Leo de todo'), findsOneWidget);
    expect(find.text('Leyendo ahora'), findsOneWidget);
    expect(find.text('Entre dos tormentas'), findsWidgets);
    expect(find.textContaining('Pág. 120 de 300 · 40%'), findsOneWidget);
    expect(find.textContaining('“Me está encantando”'), findsOneWidget);
    expect(find.text('Reaccionar'), findsOneWidget);
    expect(find.text('Lucía no comparte su biblioteca.'), findsOneWidget);
    expect(find.text('Lucía no comparte sus reseñas.'), findsOneWidget);
  });

  testWidgets('reaccionar cambia las cuentas y repetir la reacción la quita', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaccionesProgreso(
            lectura: _lectura(reacciones: {ReaccionComentario.aplaudir: 1}),
            reaccionar: (l, r) async => l.conReaccion(
              reacciones: {...l.reacciones, r: (l.reacciones[r] ?? 0) + 1},
              miReaccion: r,
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('👏 1'), findsOneWidget);
    await tester.tap(find.text('Reaccionar'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Me encanta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('❤️ 1'), findsOneWidget);
    expect(find.textContaining('👏 1'), findsOneWidget);
  });

  testWidgets('si falla el guardado, vuelve al estado de antes y avisa', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaccionesProgreso(
            lectura: _lectura(),
            reaccionar: (l, r) async => null,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Reaccionar'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Me encanta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('❤️'), findsNothing);
    expect(find.text('No se ha podido guardar la reacción.'), findsOneWidget);
  });

  testWidgets(
    'la actividad de Inicio sale con datos y no ocupa nada sin ellos',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActividadAmistadesCard(
                cargar: () async => [
                  ActividadAmistad(
                    tipo: 'LEYENDO',
                    nombre: 'Lucía',
                    bookId: 'b1',
                    titulo: 'Entre dos tormentas',
                    lectura: _lectura(),
                  ),
                  const ActividadAmistad(
                    tipo: 'TERMINADO',
                    nombre: 'Marta',
                    bookId: 'b2',
                    titulo: 'Otro libro',
                    valoracion: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Qué leen tus amistades'), findsOneWidget);
      expect(
        find.textContaining('está leyendo «Entre dos tormentas» · 40%'),
        findsOneWidget,
      );
      expect(
        find.textContaining('ha terminado «Otro libro» · ⭐ 4.0'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActividadAmistadesCard(
              key: UniqueKey(),
              cargar: () async => [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Qué leen tus amistades'), findsNothing);
    },
  );
}
