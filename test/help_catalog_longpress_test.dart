// Verifica que la sección de ayuda describe correctamente la nueva
// funcionalidad de pulsación larga para ver la ficha completa desde
// el dashboard global, incluyendo los cambios introducidos en esta versión.

import 'package:club_lectura_app/pages/ayuda_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// La ayuda tiene muchas entradas largas. Usamos una ventana alta para
// que todo el contenido sea alcanzable por scrollUntilVisible y tappable.
const _testSize = Size(800, 4000);

void main() {
  group('Ayuda — pulsación larga en portadas del panel global', () {
    testWidgets(
      'existe la pregunta sobre ver ficha desde el panel sin tenerlo en biblioteca',
      (tester) async {
        await tester.binding.setSurfaceSize(_testSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(const MaterialApp(home: AyudaPage()));
        await tester.pumpAndSettle();

        // Expandir la sección Libros
        final seccionLibros = find.text('Libros');
        expect(seccionLibros, findsOneWidget);
        await tester.ensureVisible(seccionLibros);
        await tester.tap(seccionLibros);
        await tester.pumpAndSettle();

        final pregunta = find.textContaining(
          '¿Puedo ver la ficha de un libro que aparece en el panel pero no tengo',
        );
        await tester.ensureVisible(pregunta);
        expect(pregunta, findsOneWidget);
      },
    );

    testWidgets(
      'la respuesta menciona pulsación larga y las secciones del panel',
      (tester) async {
        await tester.binding.setSurfaceSize(_testSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(const MaterialApp(home: AyudaPage()));
        await tester.pumpAndSettle();

        // Expandir la sección Libros
        final seccionLibros = find.text('Libros');
        await tester.ensureVisible(seccionLibros);
        await tester.tap(seccionLibros);
        await tester.pumpAndSettle();

        // Expandir la pregunta sobre ficha del panel
        final pregunta = find.textContaining(
          '¿Puedo ver la ficha de un libro que aparece en el panel pero no tengo',
        );
        await tester.ensureVisible(pregunta);
        await tester.tap(pregunta);
        await tester.pumpAndSettle();

        // La respuesta debe estar en el árbol de widgets (quizás fuera de pantalla)
        expect(
          find.textContaining('Mantén pulsado', skipOffstage: false),
          findsWidgets,
        );
        expect(
          find.textContaining('Últimas incorporaciones', skipOffstage: false),
          findsWidgets,
        );
        expect(
          find.textContaining('Se está leyendo mucho', skipOffstage: false),
          findsWidgets,
        );
        expect(
          find.textContaining('Ver ficha completa', skipOffstage: false),
          findsWidgets,
        );
        expect(
          find.textContaining('Kit de lectura', skipOffstage: false),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'la pregunta sobre añadir desde catálogo sigue presente tras el cambio',
      (tester) async {
        await tester.binding.setSurfaceSize(_testSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(const MaterialApp(home: AyudaPage()));
        await tester.pumpAndSettle();

        // Expandir la sección Libros
        final seccionLibros = find.text('Libros');
        await tester.ensureVisible(seccionLibros);
        await tester.tap(seccionLibros);
        await tester.pumpAndSettle();

        final preguntaCatalogo = find.textContaining(
          '¿Puedo ir al detalle de un libro que acabo de añadir desde el catálogo?',
        );
        await tester.ensureVisible(preguntaCatalogo);
        expect(preguntaCatalogo, findsOneWidget);
      },
    );
  });
}
