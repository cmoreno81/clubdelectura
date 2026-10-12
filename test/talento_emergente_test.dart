import 'package:club_lectura_app/models/libro.dart';
import 'package:club_lectura_app/models/libro_agrupado.dart';
import 'package:club_lectura_app/widgets/libros/talento_emergente.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Libro _libro(Map<String, dynamic> extra) => Libro.fromJson({
  'bookId': 'b1',
  'usuario': 'Cris',
  'libro': 'Entre dos tormentas',
  'genero': 'Romance',
  ...extra,
});

const _talento = {
  'talentoEmergente': true,
  'notaAutora': 'Gracias por leerme',
  'enlaceAutora': 'https://www.amazon.es/dp/B0TEST',
  'picanteAutora': 3,
  'troposAutora': ['slow burn', 'familia elegida'],
};

LibroAgrupado _agrupado(List<Libro> registros, {DatosTalento? catalogo}) =>
    LibroAgrupado(
      libro: 'Entre dos tormentas',
      genero: 'Romance',
      registros: registros,
      finalizados: const [],
      yaLoTengo: true,
      coverUrl: '',
      talentoCatalogo: catalogo,
    );

void main() {
  test('un libro sin sello no es talento emergente', () {
    final a = _agrupado([_libro({})]);
    expect(a.esTalentoEmergente, isFalse);
    expect(a.notaAutora, isEmpty);
  });

  test('el sello y los datos de la autora salen del registro', () {
    final a = _agrupado([_libro(_talento)]);
    expect(a.esTalentoEmergente, isTrue);
    expect(a.notaAutora, 'Gracias por leerme');
    expect(a.picanteAutora, 3);
    expect(a.troposAutora, ['slow burn', 'familia elegida']);
    expect(a.enlaceAutora, startsWith('https://'));
  });

  test('sin registros, salen de los datos del catálogo', () {
    final a = _agrupado(
      const [],
      catalogo: DatosTalento.fromJson(Map<String, dynamic>.from(_talento)),
    );
    expect(a.esTalentoEmergente, isTrue);
    expect(a.notaAutora, 'Gracias por leerme');
  });

  testWidgets('la tarjeta «De la autora» enseña nota, picante, tropos y enlace', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TarjetaDeLaAutora(libro: _agrupado([_libro(_talento)])),
          ),
        ),
      ),
    );
    expect(find.text('De la autora'), findsOneWidget);
    expect(find.textContaining('Gracias por leerme'), findsOneWidget);
    expect(find.textContaining('3 de 5'), findsOneWidget);
    expect(find.text('slow burn'), findsOneWidget);
    expect(find.text('Ver el libro de la autora'), findsOneWidget);
    expect(find.text('✨ Talento emergente'), findsOneWidget);
  });

  testWidgets('sin sello la tarjeta no ocupa nada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TarjetaDeLaAutora(libro: _agrupado([_libro({})])),
        ),
      ),
    );
    expect(find.text('De la autora'), findsNothing);
  });
}
