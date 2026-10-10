import 'package:club_lectura_app/pages/paleta_lectura_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String>? resultado;

  Future<void> abrir(WidgetTester tester) async {
    resultado = null;
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  resultado = await Navigator.push<List<String>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaletaLecturaPage(
                        bookId: 'b1',
                        libro: 'Libro de prueba',
                      ),
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
  }

  testWidgets('se puede cambiar un color y la paleta pasa a personalizada', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.textContaining('Combinación 1 de 4'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Momentos favoritos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Momentos favoritos'));
    await tester.pumpAndSettle();

    // Hoja del editor: se escribe un HEX exacto y se acepta.
    await tester.enterText(find.byType(TextField), '#FF0000');
    await tester.pump();
    await tester.tap(find.text('Usar este color'));
    await tester.pumpAndSettle();

    expect(find.text('Combinación personalizada'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Usar esta paleta'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Usar esta paleta'));
    await tester.pumpAndSettle();

    expect(resultado, isNotNull);
    expect(resultado, hasLength(5));
    expect(resultado!.first, '#FF0000');
  });

  testWidgets('elegir un color de la rejilla lo aplica', (tester) async {
    await abrir(tester);
    await tester.scrollUntilVisible(
      find.text('Teorías'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Teorías'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Color #FF8FB8'));
    await tester.pump();
    await tester.tap(find.text('Usar este color'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Usar esta paleta'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Usar esta paleta'));
    await tester.pumpAndSettle();

    expect(resultado![1], '#FF8FB8');
  });

  testWidgets('un código HEX incompleto no se puede aceptar', (tester) async {
    await abrir(tester);
    await tester.scrollUntilVisible(
      find.text('Citas'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Citas'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '#FF00');
    await tester.pump();

    final boton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Usar este color'),
    );
    expect(boton.onPressed, isNull);
    expect(find.text('Escribe 6 letras o números'), findsOneWidget);
  });

  testWidgets('hay colores oscuros para los libros de portada negra', (
    tester,
  ) async {
    await abrir(tester);
    await tester.scrollUntilVisible(
      find.text('Citas'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Citas'));
    await tester.pumpAndSettle();

    // Negro, granate y rojo disponibles en la rejilla.
    expect(find.bySemanticsLabel('Color #141416'), findsOneWidget);
    expect(find.bySemanticsLabel('Color #D62839'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Color #7B1E2E'));
    await tester.pump();
    await tester.tap(find.text('Usar este color'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Usar esta paleta'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Usar esta paleta'));
    await tester.pumpAndSettle();

    expect(resultado![2], '#7B1E2E');
  });

  testWidgets('al volver a entrar se muestra la paleta que ya se guardó', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    resultado = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                resultado = await Navigator.push<List<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaletaLecturaPage(
                      bookId: 'b1',
                      libro: 'Libro de prueba',
                      paletaGuardada: [
                        '#D62839',
                        '#141416',
                        '#F9D71C',
                        '#5DBB63',
                        '#7B1E2E',
                      ],
                    ),
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Combinación personalizada'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Usar esta paleta'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Usar esta paleta'));
    await tester.pumpAndSettle();

    expect(resultado, ['#D62839', '#141416', '#F9D71C', '#5DBB63', '#7B1E2E']);
  });

  testWidgets('si lo guardado es una propuesta automática se indica cuál', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Sin portada se usa la paleta de reserva: la primera propuesta es esta.
    await tester.pumpWidget(
      const MaterialApp(
        home: PaletaLecturaPage(
          bookId: 'b1',
          libro: 'Libro',
          paletaGuardada: [
            '#68489A',
            '#B25A83',
            '#6E8292',
            '#B98A72',
            '#384B48',
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Usar esta paleta'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Combinación 1 de 4'), findsOneWidget);
  });
}
