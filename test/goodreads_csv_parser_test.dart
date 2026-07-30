import 'dart:convert';
import 'dart:typed_data';

import 'package:club_lectura_app/services/goodreads_csv_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = GoodreadsCsvParser();

  Uint8List csv(String value) => Uint8List.fromList(utf8.encode(value));

  test('parses Goodreads fields, quoted commas and dates', () {
    final rows = parser.parse(
      csv(
        'Book Id,Title,Author,Additional Authors,ISBN,ISBN13,My Rating,'
        'Number of Pages,Year Published,Date Read,Date Added,Exclusive Shelf,My Review\n'
        '1,"A title, with comma","Doe, Jane",,"=""1234567890""",'
        '"=""9781234567890""",5,420,2024,2026/07/12,2024/03/02,read,'
        '"A review, with comma"\n',
      ),
    );

    expect(rows, hasLength(1));
    expect(rows.single.title, 'A title, with comma');
    expect(rows.single.author, 'Doe, Jane');
    expect(rows.single.isbn13, '9781234567890');
    expect(rows.single.rating, 5);
    expect(rows.single.pages, 420);
    expect(rows.single.dateRead, '2026-07-12T12:00:00.000Z');
    expect(rows.single.dateAdded, '2024-03-02T12:00:00.000Z');
    expect(rows.single.exclusiveShelf, 'read');
  });

  test('supports multiline reviews', () {
    final rows = parser.parse(
      csv(
        'Title,Author,Exclusive Shelf,My Review\n'
        '"Book","Author",to-read,"First line\nSecond line"\n',
      ),
    );

    expect(rows.single.review, 'First line\nSecond line');
  });

  test('rejects a CSV that is not a Goodreads export', () {
    expect(
      () => parser.parse(csv('name,value\none,two\n')),
      throwsFormatException,
    );
  });
}
