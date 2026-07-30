import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../models/goodreads_import.dart';

class BookmoryXlsxParser {
  const BookmoryXlsxParser();

  List<GoodreadsImportRow> parse(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
    final sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
    if (sharedStringsFile == null || sheetFile == null) {
      throw const FormatException(
        'No parece un archivo exportado por Bookmory.',
      );
    }

    final sharedStrings = _readSharedStrings(sharedStringsFile);
    final rows = _readRows(sheetFile, sharedStrings);
    if (rows.length < 3) {
      throw const FormatException('El archivo de Bookmory está vacío.');
    }

    final headers = <String, int>{};
    for (var column = 0; column < rows[1].length; column++) {
      final header = _normalize(rows[1][column]);
      if (header.isNotEmpty && !headers.containsKey(header)) {
        headers[header] = column;
      }
    }
    if (!headers.containsKey('titulo') ||
        !headers.containsKey('autores as') ||
        !headers.containsKey('estado')) {
      throw const FormatException(
        'No parece un archivo exportado por Bookmory.',
      );
    }

    String value(List<String> row, int column) =>
        column < row.length ? row[column].trim() : '';

    final titleColumn = headers['titulo']!;
    final authorColumn = headers['autores as']!;
    final isbnColumn = headers['isbn'];
    final pagesColumn = headers['total de paginas'];
    final publicationColumn = headers['fecha de publicacion'];
    final statusColumn = headers['estado']!;
    final firstPeriodColumn = headers['periodo de lectura'] ?? 14;
    final firstRatingColumn = headers['calificaciones de estrellas'] ?? 15;

    return rows
        .skip(2)
        .where((row) => value(row, titleColumn).isNotEmpty)
        .map((row) {
          final firstReading = _reading(
            row,
            periodColumn: firstPeriodColumn,
            ratingColumn: firstRatingColumn,
          );
          final secondReading = _reading(
            row,
            periodColumn: firstPeriodColumn + 4,
            ratingColumn: firstRatingColumn + 4,
          );
          final reading = secondReading.rating != null
              ? secondReading
              : firstReading;
          final finished = _normalize(
            value(row, statusColumn),
          ).contains('lo termine de leer');
          final isbn = isbnColumn == null ? '' : _isbn(value(row, isbnColumn));

          return GoodreadsImportRow(
            title: value(row, titleColumn),
            author: value(row, authorColumn),
            additionalAuthors: const [],
            isbn: isbn.length == 10 ? isbn : '',
            isbn13: isbn.length == 13 ? isbn : '',
            rating: reading.rating,
            pages: pagesColumn == null ? null : _pages(value(row, pagesColumn)),
            publicationYear: publicationColumn == null
                ? null
                : _year(value(row, publicationColumn)),
            dateRead: reading.endDate,
            dateAdded: reading.startDate,
            exclusiveShelf: finished ? 'read' : 'to-read',
            review: reading.review,
          );
        })
        .toList(growable: false);
  }

  List<String> _readSharedStrings(ArchiveFile file) {
    final document = XmlDocument.parse(_fileText(file));
    return document
        .findAllElements('si')
        .map(
          (item) =>
              item.findAllElements('t').map((text) => text.innerText).join(),
        )
        .toList(growable: false);
  }

  List<List<String>> _readRows(ArchiveFile file, List<String> sharedStrings) {
    final document = XmlDocument.parse(_fileText(file));
    return document
        .findAllElements('row')
        .map((row) {
          final values = <int, String>{};
          var maxColumn = -1;
          for (final cell in row.findElements('c')) {
            final reference = cell.getAttribute('r') ?? '';
            final column = _columnIndex(reference);
            if (column < 0) continue;
            final raw = cell.findElements('v').firstOrNull?.innerText ?? '';
            final type = cell.getAttribute('t');
            final sharedIndex = type == 's' ? int.tryParse(raw) : null;
            values[column] =
                sharedIndex != null &&
                    sharedIndex >= 0 &&
                    sharedIndex < sharedStrings.length
                ? sharedStrings[sharedIndex]
                : raw;
            if (column > maxColumn) maxColumn = column;
          }
          return List<String>.generate(
            maxColumn + 1,
            (column) => values[column] ?? '',
            growable: false,
          );
        })
        .toList(growable: false);
  }

  _BookmoryReading _reading(
    List<String> row, {
    required int periodColumn,
    required int ratingColumn,
  }) {
    String value(int column) => column < row.length ? row[column].trim() : '';
    final dates = _period(value(periodColumn));
    return _BookmoryReading(
      startDate: dates.$1,
      endDate: dates.$2,
      rating: _rating(value(ratingColumn)),
      review: value(ratingColumn + 1),
    );
  }

  (String, String) _period(String value) {
    final parts = value.split('~').map((part) => part.trim()).toList();
    if (parts.isEmpty) return ('', '');
    final start = _isoDate(parts.first);
    final end = parts.length > 1 ? _isoDate(parts.last) : start;
    return (start, end);
  }

  String _isoDate(String value) {
    final match = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})$',
    ).firstMatch(value.trim());
    if (match == null) return '';
    final day = match.group(1)!.padLeft(2, '0');
    final month = match.group(2)!.padLeft(2, '0');
    final year = match.group(3)!;
    return '$year-$month-${day}T12:00:00.000Z';
  }

  double? _rating(String value) {
    final rating = double.tryParse(value.replaceAll(',', '.'));
    return rating != null && rating >= 1 && rating <= 5 ? rating : null;
  }

  int? _pages(String value) {
    if (value.contains('%')) return null;
    final match = RegExp(r'(\d[\d.,]*)').firstMatch(value);
    if (match == null) return null;
    final digits = match.group(1)!.replaceAll(RegExp(r'[^0-9]'), '');
    final pages = int.tryParse(digits);
    return pages != null && pages > 0 ? pages : null;
  }

  int? _year(String value) {
    final match = RegExp(r'\b(1[5-9]\d{2}|20\d{2})\b').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  String _isbn(String value) {
    final isbn = value.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
    return isbn.length == 10 || isbn.length == 13 ? isbn : '';
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  int _columnIndex(String reference) {
    final letters = RegExp(r'^[A-Z]+').stringMatch(reference);
    if (letters == null) return -1;
    var result = 0;
    for (final code in letters.codeUnits) {
      result = result * 26 + code - 64;
    }
    return result - 1;
  }

  String _fileText(ArchiveFile file) =>
      utf8.decode(file.content as List<int>, allowMalformed: true);
}

class _BookmoryReading {
  const _BookmoryReading({
    required this.startDate,
    required this.endDate,
    required this.rating,
    required this.review,
  });

  final String startDate;
  final String endDate;
  final double? rating;
  final String review;
}
