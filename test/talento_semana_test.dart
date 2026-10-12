import 'package:club_lectura_app/models/libro.dart';
import 'package:club_lectura_app/models/libro_agrupado.dart';
import 'package:club_lectura_app/services/talento_semana_service.dart';
import 'package:club_lectura_app/widgets/inicio/talento_de_la_semana_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la respuesta del servidor se convierte en el libro de la semana', () {
    final libro = TalentoDeLaSemana.fromJson({
      'ok': true,
      'libro': {
        'bookId': 'b1',
        'titulo': 'Entre dos tormentas',
        'autora': 'Lucía Marín',
        'generos': ['Romance', 'Paranormal'],
        'notaAutora': 'Gracias',
        'picanteAutora': 3,
        'troposAutora': ['slow burn'],
      },
    });
    expect(libro?.titulo, 'Entre dos tormentas');
    expect(libro?.generos, ['Romance', 'Paranormal']);
    expect(TalentoDeLaSemana.fromJson({'ok': true, 'libro': null}), isNull);
  });

  testWidgets('la tarjeta enseña el libro y lo abre; sin libro no ocupa nada', (
    tester,
  ) async {
    TalentoDeLaSemana? abierto;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TalentoDeLaSemanaCard(
              cargar: () async => const TalentoDeLaSemana(
                bookId: 'b1',
                titulo: 'Entre dos tormentas',
                autoria: 'Lucía Marín',
                coverUrl: '',
                generos: ['Romance'],
                nota: 'Gracias por leerme',
              ),
              onAbrir: (l) => abierto = l,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Talento de la semana'), findsOneWidget);
    expect(find.text('Entre dos tormentas'), findsWidgets); // título y portada vacía
    expect(find.textContaining('Gracias por leerme'), findsOneWidget);
    await tester.tap(find.text('Descubrir este libro'));
    expect(abierto?.bookId, 'b1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TalentoDeLaSemanaCard(
            cargar: () async => null,
            onAbrir: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Talento de la semana'), findsNothing);
  });

  test('una entrada solo de catálogo no cuenta como lectora', () {
    Libro l(Map<String, dynamic> extra) => Libro.fromJson({
      'bookId': 'b1',
      'usuario': 'Cris',
      'libro': 'X',
      'genero': 'Romance',
      ...extra,
    });
    final agrupado = LibroAgrupado(
      libro: 'X',
      genero: 'Romance',
      registros: [
        l({'usuario': '', 'soloCatalogo': true}),
      ],
      finalizados: const [],
      yaLoTengo: false,
      coverUrl: '',
    );
    expect(agrupado.total, 0);
    final conLectora = LibroAgrupado(
      libro: 'X',
      genero: 'Romance',
      registros: [
        l({'usuario': '', 'soloCatalogo': true}),
        l({}),
      ],
      finalizados: const [],
      yaLoTengo: false,
      coverUrl: '',
    );
    expect(conLectora.total, 1);
  });
}
