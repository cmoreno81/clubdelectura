import 'package:club_lectura_app/models/libro.dart';
import 'package:club_lectura_app/models/libro_agrupado.dart';
import 'package:club_lectura_app/models/nuevo_libro.dart';
import 'package:flutter_test/flutter_test.dart';

Libro _libro(Map<String, dynamic> extra) => Libro.fromJson({
  'bookId': 'b1',
  'usuario': 'Cris',
  'libro': 'Un libro',
  'genero': 'Fantasía',
  ...extra,
});

void main() {
  test('Libro lee la lista de géneros y tolera su ausencia', () {
    expect(
      _libro({
        'generos': ['Fantasía', 'Juvenil'],
      }).generos,
      ['Fantasía', 'Juvenil'],
    );
    expect(_libro({}).generos, isEmpty);
  });

  test('LibroAgrupado deduce los géneros de sus registros o del principal', () {
    LibroAgrupado agrupado(List<Libro> registros) => LibroAgrupado(
      libro: 'Un libro',
      genero: 'Fantasía',
      registros: registros,
      finalizados: const [],
      yaLoTengo: true,
      coverUrl: '',
    );

    expect(agrupado(const []).generosLista, ['Fantasía']);
    expect(agrupado([_libro({})]).generosLista, ['Fantasía']);
    expect(
      agrupado([
        _libro({
          'generos': ['Fantasía', 'Juvenil'],
        }),
      ]).generosLista,
      ['Fantasía', 'Juvenil'],
    );
  });

  test('NuevoLibro envía los géneros adicionales', () {
    final json = NuevoLibro(
      usuario: 'Cris',
      libro: 'Un libro',
      genero: 'Fantasía',
      generosExtra: const ['Juvenil'],
      saga: '',
      numSaga: '',
      autoconclusivo: 'Si',
      prioridad: '',
    ).toJson();
    expect(json['genero'], 'Fantasía');
    expect(json['generosExtra'], ['Juvenil']);
  });
}
