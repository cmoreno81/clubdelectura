import 'package:club_lectura_app/models/amistad.dart';
import 'package:club_lectura_app/pages/amistades_page.dart';
import 'package:club_lectura_app/widgets/inicio/amistades_atajo_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _datos = AmistadesData(
  miCodigo: 'ABCD-2345',
  amistades: [PersonaAmistad(nombre: 'Lucía')],
  recibidas: [PersonaAmistad(nombre: 'Marta')],
  enviadas: [PersonaAmistad(nombre: 'Noa')],
);

void main() {
  test('el servidor se convierte en listas de amistades y estados', () {
    final data = AmistadesData.fromJson({
      'miCodigo': 'ABCD-2345',
      'amistades': [
        {'nombre': 'Lucía', 'avatarUrl': 'https://x/a.png'},
      ],
      'recibidas': [
        {'nombre': 'Marta'},
      ],
    });
    expect(data.miCodigo, 'ABCD-2345');
    expect(data.amistades.single.avatarUrl, 'https://x/a.png');
    expect(data.recibidas.single.nombre, 'Marta');
    expect(data.enviadas, isEmpty);
    expect(EstadoAmistad.desde('ENVIADA'), EstadoAmistad.enviada);
    expect(EstadoAmistad.desde('RECIBIDA'), EstadoAmistad.recibida);
    expect(EstadoAmistad.desde('AMIGA'), EstadoAmistad.amiga);
    expect(EstadoAmistad.desde(null), EstadoAmistad.ninguna);
  });

  testWidgets('la pantalla enseña tu código, el buscador y las tres listas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: AmistadesPage(cargar: () async => _datos)),
    );
    await tester.pumpAndSettle();

    expect(find.text('ABCD-2345'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('Compartir'), findsOneWidget);
    expect(find.text('Solicitudes recibidas (1)'), findsOneWidget);
    expect(find.text('Marta'), findsOneWidget);
    expect(find.text('Aceptar'), findsOneWidget);
    expect(find.text('Rechazar'), findsOneWidget);
    expect(find.text('Solicitudes enviadas (1)'), findsOneWidget);
    expect(find.text('Noa'), findsOneWidget);
    expect(find.text('Tus amigos (1)'), findsOneWidget);
    expect(find.text('Lucía'), findsOneWidget);
    expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
    expect(find.textContaining('mínimo 3 letras'), findsOneWidget);
  });

  testWidgets(
    'sin amistades la pantalla invita a buscar o compartir el código',
    (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: AmistadesPage(
            cargar: () async => const AmistadesData(miCodigo: 'ABCD-2345'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Todavía no tienes amigos'),
        findsOneWidget,
      );
      expect(find.text('Solicitudes recibidas (0)'), findsNothing);
    },
  );

  testWidgets('el atajo de Inicio avisa de solicitudes y se oculta si falla', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AmistadesAtajoCard(cargar: () async => _datos)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Amigos'), findsOneWidget);
    expect(find.text('1 solicitud por responder'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmistadesAtajoCard(
            key: UniqueKey(),
            cargar: () async => throw Exception('servidor antiguo'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Amigos'), findsNothing);
  });

  test('el club en común se lee de la lista y de la búsqueda', () {
    final data = AmistadesData.fromJson({
      'amistades': [
        {'nombre': 'Lucía', 'clubEnComun': ''},
        {'nombre': 'Ana', 'clubEnComun': 'Club Lunar'},
      ],
    });
    expect(data.amistades.map((a) => a.clubEnComun), ['', 'Club Lunar']);
    final p = PersonaBuscada.fromJson({
      'nombre': 'Ana',
      'clubEnComun': 'Club Lunar',
    });
    expect(p.clubEnComun, 'Club Lunar');
  });

  testWidgets('en la lista, quien es de tu club lo indica', (tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AmistadesPage(
          cargar: () async => const AmistadesData(
            miCodigo: 'X',
            amistades: [
              PersonaAmistad(nombre: 'Lucía'),
              PersonaAmistad(nombre: 'Ana', clubEnComun: 'Club Lunar'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('De tu club «Club Lunar»'), findsOneWidget);
    expect(find.textContaining('De tu club'), findsOneWidget);
  });
}
