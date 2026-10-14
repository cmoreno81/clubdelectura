import 'package:club_lectura_app/pages/autor_libros_page.dart';
import 'package:club_lectura_app/utils/idioma_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _libro(String titulo, String idioma, {String saga = ''}) =>
    {
      'id': titulo,
      'titulo': titulo,
      'coverUrl': '',
      'genero': 'Romance',
      'idioma': idioma,
      if (saga.isNotEmpty) 'sagaNombre': saga,
    };

void main() {
  test(
    'los libros se agrupan por idioma: español, inglés, resto y sin idioma',
    () {
      final grupos = agruparLibrosPorIdioma([
        _libro('Mortal', ''),
        _libro('Deep End', 'en'),
        _libro('Caída libre', 'es'),
        _libro('Le jeu', 'fr'),
        _libro('Check & Mate', 'en'),
        _libro('Amor de miedo', 'es'),
      ]);
      expect(grupos.map((g) => g.codigo), ['es', 'en', 'fr', '']);
      expect(grupos[0].libros.map((l) => l['titulo']), [
        'Amor de miedo',
        'Caída libre',
      ]);
      expect(grupos[1].libros.map((l) => l['titulo']), [
        'Check & Mate',
        'Deep End',
      ]);
    },
  );

  testWidgets('la ficha de autoría separa los independientes por idioma', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AutorLibrosPage(
          autorId: 'a1',
          nombre: 'Ali Hazelwood',
          photoUrl: '',
          cargar: (_) async => {
            'biografia': '',
            'libros': [
              _libro('Caída libre', 'es'),
              _libro('Deep End', 'en'),
              _libro('Jaque mate al amor', 'es'),
              _libro('Check & Mate', 'en'),
            ],
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('🇪🇸 Español (2)'), findsOneWidget);
    expect(find.text('🇬🇧 Inglés (2)'), findsOneWidget);
  });

  testWidgets(
    'si todos los libros son del mismo idioma no se añaden secciones',
    (tester) async {
      tester.view.physicalSize = const Size(900, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: AutorLibrosPage(
            autorId: 'a1',
            nombre: 'Ali Hazelwood',
            photoUrl: '',
            cargar: (_) async => {
              'biografia': '',
              'libros': [_libro('Caída libre', 'es'), _libro('Mortal', 'es')],
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Español ('), findsNothing);
      expect(find.text('Caída libre'), findsWidgets);
    },
  );
}
