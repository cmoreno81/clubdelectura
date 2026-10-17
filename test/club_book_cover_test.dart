import 'package:club_lectura_app/widgets/common/club_book_cover.dart';
import 'package:club_lectura_app/widgets/common/portada_sin_imagen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('acepta un ancho infinito dentro de una cuadrícula', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 110,
            child: ClubBookCover(
              title: 'Libro de prueba',
              imageUrl: 'https://example.invalid/cover.jpg',
              width: double.infinity,
              height: 140,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ClubBookCover), findsOneWidget);
  });

  test('el color de la portada sin imagen es estable y depende del título', () {
    expect(
      PortadaSinImagen.indiceDe('La torre oscura'),
      PortadaSinImagen.indiceDe('  la torre OSCURA '),
    );
    final indices = {
      for (final t in [
        'Dune',
        'Babel',
        'Yellowface',
        'Piranesi',
        'Alas de sangre',
      ])
        PortadaSinImagen.indiceDe(t),
    };
    expect(indices.length, greaterThan(1));
  });

  testWidgets('sin imagen sale el título en cualquier tamaño, sin errores', (
    tester,
  ) async {
    for (final ancho in [36.0, 58.0, 96.0, 160.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ClubBookCover(
                title: 'El día de la Trilla (Empíreo)',
                width: ancho,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'ancho $ancho');
      expect(find.text('El día de la Trilla (Empíreo)'), findsOneWidget);
    }
  });
}
