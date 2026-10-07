import 'package:club_lectura_app/models/libro_finalizado.dart';
import 'package:club_lectura_app/widgets/libros/mi_ficha_lectura_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LibroFinalizado _finalizado(String formato) => LibroFinalizado.fromJson({
  'bookId': 'b1',
  'usuario': 'Cris M.',
  'libro': 'El príncipe cruel',
  'genero': 'Fantasía',
  'saga': '',
  'numSaga': '',
  'autoconclusivo': 'Si',
  'valoracion': '4',
  'resena': '',
  'coverUrl': '',
  'avatarUrl': '',
  'formato': formato,
  'idioma': 'es',
  'yaLoTengo': true,
});

Future<void> _pinta(WidgetTester tester, String formato) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: MiFichaLecturaCard(
          finalizado: _finalizado(formato),
          onCambiado: () {},
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('junto al idioma se ve el formato con el que se leyó', (
    tester,
  ) async {
    await _pinta(tester, 'DIGITAL');
    expect(find.text('Idioma que leí'), findsOneWidget);
    expect(find.text('Formato que leí'), findsOneWidget);
    expect(find.text('Ebook'), findsOneWidget);
  });

  testWidgets('sin formato se ofrece indicarlo y el selector lista los tres', (
    tester,
  ) async {
    await _pinta(tester, '');
    expect(find.text('Sin especificar'), findsOneWidget);
    await tester.tap(find.text('Sin especificar'));
    await tester.pumpAndSettle();
    expect(find.text('Papel'), findsOneWidget);
    expect(find.text('Ebook'), findsOneWidget);
    expect(find.text('Audiolibro'), findsOneWidget);
  });
}
