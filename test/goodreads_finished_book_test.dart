import 'dart:io';

import 'package:club_lectura_app/models/libro.dart';
import 'package:club_lectura_app/models/libro_agrupado.dart';
import 'package:club_lectura_app/models/libro_finalizado.dart';
import 'package:club_lectura_app/widgets/libros/libro_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const goodreadsUrl =
    'https://www.goodreads.com/book/show/223950662-amor-en-pr-stamo';

void main() {
  test('un libro activo conserva Goodreads', () {
    expect(
      Libro.fromJson({'goodreads': goodreadsUrl, ..._bookJson}).goodreads,
      goodreadsUrl,
    );
    expect(
      Libro.fromJson({'goodreadsUrl': goodreadsUrl, ..._bookJson}).goodreads,
      goodreadsUrl,
    );
  });

  test('una finalización normal conserva Goodreads', () {
    expect(
      LibroFinalizado.fromJson({
        ..._finishedJson,
        'goodreads': goodreadsUrl,
        'isReread': false,
      }).goodreads,
      goodreadsUrl,
    );
  });

  test('una relectura finalizada conserva Goodreads con goodreadsUrl', () {
    expect(
      LibroFinalizado.fromJson({
        ..._finishedJson,
        'goodreadsUrl': goodreadsUrl,
        'isReread': true,
      }).goodreads,
      goodreadsUrl,
    );
  });

  test('LibroAgrupado busca el primer Goodreads no vacío defensivamente', () {
    final grouped = _grouped(
      registros: [_active(''), _active(goodreadsUrl)],
      finalizados: [_finished('https://goodreads.com/otro')],
    );
    expect(grouped.goodreads, goodreadsUrl);
    expect(
      _grouped(finalizados: [_finished(goodreadsUrl)]).goodreads,
      goodreadsUrl,
    );
    expect(_grouped().goodreads, isEmpty);
  });

  testWidgets('el detalle cubre finalización normal y relectura finalizada', (
    tester,
  ) async {
    Future<void> pump(LibroAgrupado book) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LibroHeader(libro: book, referencia: null),
          ),
        ),
      ),
    );

    await pump(
      _grouped(finalizados: [_finished(goodreadsUrl, isReread: false)]),
    );
    expect(find.text('Ver ficha en Goodreads'), findsOneWidget);

    await pump(_grouped());
    expect(find.text('Ver ficha en Goodreads'), findsNothing);

    await pump(
      _grouped(finalizados: [_finished(goodreadsUrl, isReread: true)]),
    );
    expect(find.text('Ver ficha en Goodreads'), findsOneWidget);
  });

  test('la conversión y la edición reutilizan Goodreads del agrupado', () {
    final librosPage = File('lib/pages/libros_page.dart').readAsStringSync();
    final nuevoLibro = File(
      'lib/pages/nuevo_libro_page.dart',
    ).readAsStringSync();
    final detalle = File(
      'lib/pages/detalle_libro_page.dart',
    ).readAsStringSync();
    expect(librosPage, contains('goodreads: finalizado.goodreads'));
    expect(
      nuevoLibro,
      contains('goodreadsController.text = agrupado.goodreads'),
    );
    expect(detalle, contains('var url = libro.goodreads'));
  });
}

const _bookJson = <String, dynamic>{
  'bookId': 'book-1',
  'usuario': 'Bea',
  'libro': 'Amor en préstamo',
  'genero': 'Romance',
  'saga': '',
  'numSaga': '',
  'autoconclusivo': 'SI',
  'prioridad': 'MEDIA',
  'estado': 'READING',
  'valoracion': '',
  'yaLoTengo': true,
  'coverUrl': '',
  'pauseReason': '',
  'avatarUrl': '',
};

const _finishedJson = <String, dynamic>{
  'bookId': 'book-1',
  'usuario': 'Bea',
  'libro': 'Amor en préstamo',
  'genero': 'Romance',
  'saga': '',
  'numSaga': '',
  'autoconclusivo': 'SI',
  'valoracion': '5',
  'resena': '',
  'coverUrl': '',
  'avatarUrl': '',
};

Libro _active(String goodreads) =>
    Libro.fromJson({..._bookJson, 'goodreads': goodreads});

LibroFinalizado _finished(String goodreads, {bool isReread = false}) =>
    LibroFinalizado.fromJson({
      ..._finishedJson,
      'goodreads': goodreads,
      'isReread': isReread,
    });

LibroAgrupado _grouped({
  List<Libro> registros = const [],
  List<LibroFinalizado> finalizados = const [],
}) => LibroAgrupado(
  libro: 'Amor en préstamo',
  genero: 'Romance',
  registros: registros,
  finalizados: finalizados,
  yaLoTengo: false,
  coverUrl: '',
);
