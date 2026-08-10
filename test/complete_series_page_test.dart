import 'package:club_lectura_app/models/catalog_book.dart';
import 'package:club_lectura_app/widgets/sagas/series_volume_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'muestra las opciones de estado para libros ya en la biblioteca',
    (tester) async {
      final book = CatalogBook(
        id: 'book-1',
        source: 'CLUBREADS',
        title: 'El libro',
        authors: const ['Autor'],
        coverUrl: '',
        genre: 'Ficción',
        isbn: '',
        inMyLibrary: true,
        status: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeriesVolumeDetailsDialog(
              book: book,
              preservePersonalData: false,
              initialOrder: '1',
              initialStatus: 'PENDIENTE',
              initialFormat: '',
              initialRating: '',
              initialStartDate: null,
              initialEndDate: null,
            ),
          ),
        ),
      );

      expect(find.text('Estado (opcional)'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Leyendo'), findsOneWidget);
      expect(find.text('Terminado'), findsOneWidget);
    },
  );
}
