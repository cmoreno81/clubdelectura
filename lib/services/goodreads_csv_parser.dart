import 'dart:convert';
import 'dart:typed_data';

import '../models/goodreads_import.dart';

class GoodreadsCsvParser {
  const GoodreadsCsvParser();

  List<GoodreadsImportRow> parse(Uint8List bytes) {
    final text = utf8
        .decode(bytes, allowMalformed: true)
        .replaceFirst('\ufeff', '');
    final table = _parseCsv(text);
    if (table.isEmpty) {
      throw const FormatException('El archivo está vacío.');
    }

    final headers = <String, int>{};
    for (var index = 0; index < table.first.length; index++) {
      headers[_normalizeHeader(table.first[index])] = index;
    }
    if (!headers.containsKey('title') ||
        !headers.containsKey('author') ||
        !headers.containsKey('exclusive shelf')) {
      throw const FormatException(
        'No parece un archivo exportado por Goodreads.',
      );
    }

    String value(List<String> row, String header) {
      final index = headers[header];
      if (index == null || index >= row.length) return '';
      return row[index].trim();
    }

    return table
        .skip(1)
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .map((row) {
          final additional = value(row, 'additional authors');
          return GoodreadsImportRow(
            title: value(row, 'title'),
            author: value(row, 'author'),
            additionalAuthors: additional.isEmpty
                ? const []
                : additional
                      .split(',')
                      .map((author) => author.trim())
                      .where((author) => author.isNotEmpty)
                      .toList(growable: false),
            isbn: _cleanIsbn(value(row, 'isbn')),
            isbn13: _cleanIsbn(value(row, 'isbn13')),
            rating: _rating(value(row, 'my rating')),
            pages: _integer(value(row, 'number of pages')),
            publicationYear:
                _integer(value(row, 'year published')) ??
                _integer(value(row, 'original publication year')),
            dateRead: _isoDate(value(row, 'date read')),
            dateAdded: _isoDate(value(row, 'date added')),
            exclusiveShelf: value(row, 'exclusive shelf'),
            review: value(row, 'my review'),
          );
        })
        .toList(growable: false);
  }

  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;

    void finishField() {
      row.add(field.toString());
      field.clear();
    }

    void finishRow() {
      finishField();
      rows.add(row);
      row = <String>[];
    }

    for (var index = 0; index < input.length; index++) {
      final char = input[index];
      if (char == '"') {
        if (quoted && index + 1 < input.length && input[index + 1] == '"') {
          field.write('"');
          index += 1;
        } else {
          quoted = !quoted;
        }
      } else if (char == ',' && !quoted) {
        finishField();
      } else if ((char == '\n' || char == '\r') && !quoted) {
        if (char == '\r' &&
            index + 1 < input.length &&
            input[index + 1] == '\n') {
          index += 1;
        }
        finishRow();
      } else {
        field.write(char);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) finishRow();
    return rows;
  }

  String _normalizeHeader(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _cleanIsbn(String value) => value
      .replaceAll('=', '')
      .replaceAll('"', '')
      .replaceAll(RegExp(r'[^0-9Xx]'), '')
      .toUpperCase();

  int? _integer(String value) {
    final parsed = int.tryParse(value.trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  double? _rating(String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    return parsed != null && parsed >= 1 && parsed <= 5 ? parsed : null;
  }

  String _isoDate(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';
    final match = RegExp(
      r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})$',
    ).firstMatch(raw);
    if (match == null) return '';
    final year = match.group(1)!;
    final month = match.group(2)!.padLeft(2, '0');
    final day = match.group(3)!.padLeft(2, '0');
    return '$year-$month-${day}T12:00:00.000Z';
  }
}
