import 'package:club_lectura_app/models/catalog_book.dart';
import 'package:club_lectura_app/pages/catalog_book_detail_page.dart';
import 'package:club_lectura_app/widgets/book_of_year/book_of_year_bracket_preview.dart';
import 'package:club_lectura_app/widgets/common/club_book_cover.dart';
import 'package:club_lectura_app/widgets/libros/add_book_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra una ficha pública completa sin datos personales', (
    tester,
  ) async {
    final book = _book(
      description: 'Una sinopsis real.',
      goodreadsUrl: 'https://goodreads.com/book/show/1',
      publisher: 'Editorial Jade',
      language: 'Español',
      publicationDate: '2024-03-12',
      series: 'La Saga Verde',
      seriesPosition: '2',
    );
    await _pump(tester, book: book);

    expect(find.text('Ciudad de Jade'), findsWidgets);
    expect(find.text('Fonda Lee'), findsOneWidget);
    expect(find.text('Fantasía'), findsOneWidget);
    expect(find.text('512 páginas'), findsOneWidget);
    expect(find.text('La Saga Verde · Libro 2'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Una sinopsis real.'), findsOneWidget);
    expect(find.text('Ver ficha en Goodreads'), findsOneWidget);
    expect(find.text('Editorial Jade'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    expect(find.text('Añadir a mi biblioteca'), findsOneWidget);
    expect(find.byType(BookOfYearBracketPreview), findsNothing);
  });

  testWidgets('omite limpiamente los metadatos que no existen', (tester) async {
    await _pump(
      tester,
      book: _book(
        pages: null,
        coverUrl: '',
        description: '',
        goodreadsUrl: '',
        isbn: '',
        publicationYear: null,
      ),
    );

    expect(find.text('Sinopsis'), findsNothing);
    expect(find.text('Datos editoriales'), findsNothing);
    expect(find.text('Ver ficha en Goodreads'), findsNothing);
    expect(find.byType(ClubBookCover), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar no guarda y confirmar actualiza sin alta duplicada', (
    tester,
  ) async {
    var saves = 0;
    AddBookPreferences? sent;
    await _pump(
      tester,
      book: _book(),
      addBook: (_, preferences) async {
        saves++;
        sent = preferences;
        return 'book-canonical';
      },
    );

    await tester.ensureVisible(find.text('Añadir a mi biblioteca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir a mi biblioteca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(find.text('Añadir a mi biblioteca'), findsOneWidget);

    await tester.ensureVisible(find.text('Añadir a mi biblioteca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir a mi biblioteca'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-book-priority-ALTA')));
    await tester.tap(find.byKey(const ValueKey('add-book-format-DIGITAL')));
    await tester.tap(find.byKey(const ValueKey('confirm-add-book')));
    await tester.pumpAndSettle();

    expect(saves, 1);
    expect(sent?.priority, 'ALTA');
    expect(sent?.format, 'DIGITAL');
    expect(find.text('¡Añadido a tu biblioteca!'), findsOneWidget);
    expect(find.text('Ver en mi biblioteca'), findsOneWidget);
    expect(find.text('Añadir a mi biblioteca'), findsNothing);
    await tester.pump();
    expect(saves, 1);
  });

  testWidgets('no desborda en pantalla estrecha con texto ampliado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pump(
      tester,
      book: _book(
        series: 'Una saga con un nombre extraordinariamente largo',
        seriesPosition: '12',
        description: 'Sinopsis extensa para comprobar el ajuste del texto.',
      ),
      textScaler: const TextScaler.linear(1.7),
    );
    expect(tester.takeException(), isNull);
  });

  for (final origin in [
    'Últimas incorporaciones',
    'Recomendaciones',
    'Libros de Fonda Lee',
  ]) {
    testWidgets('volver conserva el origen $origin', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _Origin(
            label: origin,
            destination: CatalogBookDetailPage(
              bookId: 'jade',
              title: 'Ciudad de Jade',
              coverUrl: '',
              genre: 'Fantasía',
              loadBook: (_, _) async => _book(),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(origin), findsOneWidget);
    });
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required CatalogBook book,
  Future<String> Function(CatalogBook?, AddBookPreferences)? addBook,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: CatalogBookDetailPage(
          bookId: book.id,
          title: book.title,
          coverUrl: book.coverUrl,
          genre: book.genre,
          loadBook: (_, _) async => book,
          addBook: addBook,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

CatalogBook _book({
  int? pages = 512,
  int? publicationYear = 2024,
  String coverUrl = '',
  String isbn = '9780000000001',
  String description = '',
  String goodreadsUrl = '',
  String publisher = '',
  String language = '',
  String publicationDate = '',
  String series = '',
  String seriesPosition = '',
}) => CatalogBook(
  id: 'jade',
  source: 'CLUBREADS',
  title: 'Ciudad de Jade',
  authors: const ['Fonda Lee'],
  coverUrl: coverUrl,
  genre: 'Fantasía',
  isbn: isbn,
  inMyLibrary: false,
  status: '',
  pages: pages,
  publicationYear: publicationYear,
  description: description,
  goodreadsUrl: goodreadsUrl,
  publisher: publisher,
  language: language,
  publicationDate: publicationDate,
  series: series,
  seriesPosition: seriesPosition,
);

class _Origin extends StatelessWidget {
  const _Origin({required this.label, required this.destination});
  final String label;
  final Widget destination;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text(label),
        TextButton(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => destination),
          ),
          child: const Text('Abrir'),
        ),
      ],
    ),
  );
}
