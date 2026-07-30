import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:club_lectura_app/services/bookmory_xlsx_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta dos obras homónimas como filas independientes', () {
    final values = [
      'Información del libro',
      'Registro de lectura 1',
      'Título',
      'Autores/as',
      'ISBN',
      'Total de páginas',
      'Estado',
      'Período de lectura',
      'Calificaciones de estrellas',
      'Comentario',
      'Powerless',
      'Lauren Roberts',
      '9781234567890',
      'Pág. 600',
      '¡Lo terminé de leer!',
      '1/3/2024 ~ 5/3/2024',
      '5.0',
      'Primera obra',
      'Powerless',
      'Elsie Silver',
      '9780987654321',
      'Pág. 450',
      '¡Lo terminé de leer!',
      '2/4/2024 ~ 8/4/2024',
      '4.0',
      'Segunda obra',
    ];
    final index = <String, int>{
      for (var position = 0; position < values.length; position++)
        values[position]: position,
    };
    String cell(String reference, String value) =>
        '<c r="$reference" t="s"><v>${index[value]}</v></c>';
    final sheet =
        '''
      <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <sheetData>
          <row r="1">${cell('A1', 'Información del libro')}${cell('O1', 'Registro de lectura 1')}</row>
          <row r="2">
            ${cell('A2', 'Título')}${cell('B2', 'Autores/as')}
            ${cell('I2', 'ISBN')}${cell('J2', 'Total de páginas')}
            ${cell('N2', 'Estado')}${cell('O2', 'Período de lectura')}
            ${cell('P2', 'Calificaciones de estrellas')}${cell('Q2', 'Comentario')}
          </row>
          <row r="3">
            ${cell('A3', 'Powerless')}${cell('B3', 'Lauren Roberts')}
            ${cell('I3', '9781234567890')}${cell('J3', 'Pág. 600')}
            ${cell('N3', '¡Lo terminé de leer!')}${cell('O3', '1/3/2024 ~ 5/3/2024')}
            ${cell('P3', '5.0')}${cell('Q3', 'Primera obra')}
          </row>
          <row r="4">
            ${cell('A4', 'Powerless')}${cell('B4', 'Elsie Silver')}
            ${cell('I4', '9780987654321')}${cell('J4', 'Pág. 450')}
            ${cell('N4', '¡Lo terminé de leer!')}${cell('O4', '2/4/2024 ~ 8/4/2024')}
            ${cell('P4', '4.0')}${cell('Q4', 'Segunda obra')}
          </row>
        </sheetData>
      </worksheet>
    ''';
    final sharedStrings =
        '''
      <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        ${values.map((value) => '<si><t>${htmlEscape.convert(value)}</t></si>').join()}
      </sst>
    ''';
    final archive = Archive()
      ..addFile(ArchiveFile.string('xl/sharedStrings.xml', sharedStrings))
      ..addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', sheet));
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));

    final rows = const BookmoryXlsxParser().parse(bytes);

    expect(rows, hasLength(2));
    expect(rows.map((row) => row.author), ['Lauren Roberts', 'Elsie Silver']);
    expect(rows.map((row) => row.isbn13), ['9781234567890', '9780987654321']);
    expect(rows.map((row) => row.dateRead), [
      '2024-03-05T12:00:00.000Z',
      '2024-04-08T12:00:00.000Z',
    ]);
    expect(rows.every((row) => row.exclusiveShelf == 'read'), isTrue);
  });
}
