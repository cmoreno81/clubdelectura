import 'package:club_lectura_app/pages/autor_libros_page.dart';
import 'package:club_lectura_app/utils/idioma_utils.dart';
import 'package:club_lectura_app/widgets/common/club_book_cover.dart';
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
  _pruebasTablet();
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

// Tablet: las portadas de los independientes son 2:3 y las sagas más grandes.
void _pruebasTablet() {
  testWidgets('en tablet los independientes salen en rejilla de portadas 2:3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 2400);
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
              for (var i = 0; i < 6; i++) _libro('Libro $i', 'es'),
              _libro('Saga 1', 'es', saga: 'La saga'),
              _libro('Saga 2', 'es', saga: 'La saga'),
            ],
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final portada = tester.getSize(find.byType(ClubBookCover).first);
    // Una portada de saga mide 104×156 en tablet.
    expect(portada.width, 104);
    expect(portada.height, 156);
    final rejilla = tester.getSize(find.text('Libro 0').first);
    expect(rejilla.width, greaterThan(0));
  });
}
