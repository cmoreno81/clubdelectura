import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:club_lectura_app/widgets/libros/compartir_libro_terminado.dart';

void main() {
  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  mostrarCompartirLibroTerminado(context, titulo: 'En llamas'),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('la hoja ofrece story y feed y cambia la proporción', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text('Story · 9:16'), findsOneWidget);
    expect(find.text('Feed · 4:5'), findsOneWidget);
    expect(find.text('En llamas'), findsOneWidget);

    Size tamano() => tester.getSize(find.byType(TarjetaLibroTerminado));
    final story = tamano();
    expect(story.width / story.height, closeTo(360 / 640, 0.001));

    await tester.tap(find.text('Feed · 4:5'));
    await tester.pumpAndSettle();
    final feed = tamano();
    expect(feed.width / feed.height, closeTo(360 / 450, 0.001));
  });

  test('los lienzos exportan a 1080 px de ancho', () {
    for (final f in FormatoCompartir.values) {
      expect(f.ancho * 3, 1080);
    }
    expect(FormatoCompartir.story.alto * 3, 1920);
    expect(FormatoCompartir.feed.alto * 3, 1350);
  });
}
