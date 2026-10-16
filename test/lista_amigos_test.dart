import 'package:club_lectura_app/models/amistad.dart';
import 'package:club_lectura_app/pages/amistades_page.dart';
import 'package:club_lectura_app/pages/lista_amigos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<PersonaAmistad> _gente(int n) => [
  for (var i = 1; i <= n; i++) PersonaAmistad(nombre: 'Amigo$i'),
];

void main() {
  testWidgets('el cuadro «amigos» abre la lista y se vuelve con la flecha', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AmistadesPage(
          cargar: () async => AmistadesData(
            miCodigo: 'ABCD-2345',
            amistades: [const PersonaAmistad(nombre: 'Lucía')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lucía'), findsNothing);

    await tester.tap(find.byKey(const Key('resumen-amigos')));
    await tester.pumpAndSettle();
    expect(find.text('Tus amigos'), findsOneWidget);
    expect(find.text('Lucía'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Lucía'), findsNothing);
    expect(find.text('Tus amigos'), findsNothing);
  });

  testWidgets('sin amigos el cuadro avisa y no abre nada', (tester) async {
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
    await tester.tap(find.byKey(const Key('resumen-amigos')));
    await tester.pump();
    expect(find.text('Todavía no tienes amigos.'), findsOneWidget);
    expect(find.byType(ListaAmigosPage), findsNothing);
  });

  testWidgets('con muchos amigos aparece el buscador y filtra', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ListaAmigosPage(amistades: _gente(10))),
    );
    expect(find.byKey(const Key('lista-amigos-filtro')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('lista-amigos-filtro')), '10');
    await tester.pump();
    expect(find.text('Amigo10'), findsOneWidget);
    expect(find.text('Amigo1'), findsNothing);
    await tester.enterText(find.byKey(const Key('lista-amigos-filtro')), 'zzz');
    await tester.pump();
    expect(find.text('Nadie se llama así entre tus amigos.'), findsOneWidget);
  });

  testWidgets('con pocos amigos no hay buscador; quitar pide confirmación', (
    tester,
  ) async {
    String? quitado;
    await tester.pumpWidget(
      MaterialApp(
        home: ListaAmigosPage(
          amistades: _gente(2),
          quitar: (n) async {
            quitado = n;
            return const ResultadoAmistad(ok: true);
          },
        ),
      ),
    );
    expect(find.byKey(const Key('lista-amigos-filtro')), findsNothing);
    await tester.tap(find.byIcon(Icons.person_remove_outlined).first);
    await tester.pumpAndSettle();
    expect(find.text('¿Quitar a Amigo1 de tus amigos?'), findsOneWidget);
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();
    expect(quitado, 'Amigo1');
    expect(find.text('Amigo1'), findsNothing);
    expect(find.text('Amigo2'), findsOneWidget);
  });
}
