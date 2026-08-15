import 'dart:async';

import 'package:club_lectura_app/models/catalog_book.dart';
import 'package:club_lectura_app/models/perfil_usuario.dart';
import 'package:club_lectura_app/pages/complete_series_page.dart';
import 'package:club_lectura_app/services/api_exception.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';
import 'package:club_lectura_app/widgets/sagas/series_volume_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre, selecciona estado y devuelve el volumen', (tester) async {
    SeriesVolumeSelection? selection;
    await tester.pumpWidget(
      _DialogHarness(
        book: _book(inLibrary: true),
        onResult: (value) => selection = value,
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Estado (opcional)'), findsOneWidget);
    expect(find.text('Formato (opcional)'), findsNothing);

    await tester.tap(find.text('Leyendo'));
    await tester.tap(find.widgetWithText(FilledButton, 'Añadir a la saga'));
    await tester.pumpAndSettle();

    expect(selection?.status, 'LEYENDO');
    expect(selection?.order, '1');
    expect(find.byType(SeriesVolumeDetailsDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('libro terminado preserva sus datos y permite cancelar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _DialogHarness(
        book: _book(inLibrary: true, status: 'FINALIZADO'),
        preservePersonalData: true,
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Estado (opcional)'), findsNothing);
    expect(find.text('Formato (opcional)'), findsNothing);
    expect(find.text('Valoración'), findsNothing);
    expect(find.textContaining('Solo necesitamos'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(SeriesVolumeDetailsDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin portada, autora ni metadatos permite formato y valoración', (
    tester,
  ) async {
    SeriesVolumeSelection? selection;
    await tester.pumpWidget(
      _DialogHarness(
        book: _book(inLibrary: false, title: 'Volumen sin metadatos'),
        onResult: (value) => selection = value,
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Volumen sin metadatos'), findsOneWidget);
    expect(find.text('Formato (opcional)'), findsOneWidget);
    await tester.tap(find.text('Digital'));
    await tester.tap(find.text('Terminado'));
    await tester.pump();
    expect(find.text('Fecha de inicio (opcional)'), findsOneWidget);
    expect(find.text('Fecha de fin (opcional)'), findsOneWidget);
    expect(find.text('Valoración'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('5 ★'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('5 ★'));
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Añadir a la saga'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Añadir a la saga'));
    await tester.pumpAndSettle();

    expect(selection?.format, 'DIGITAL');
    expect(selection?.status, 'FINALIZADO');
    expect(selection?.rating, '5');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'viewport pequeño mantiene el contenido desplazable sin overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 520);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _DialogHarness(
          book: _book(inLibrary: false),
          initialStatus: 'FINALIZADO',
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Añadir a la saga'),
        180,
        scrollable: find.byType(Scrollable).last,
      );

      expect(find.text('Añadir a la saga'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('la pantalla muestra carga y error con servicio inyectado', (
    tester,
  ) async {
    final pending = Completer<List<CatalogBook>>();
    await tester.pumpWidget(
      MaterialApp(
        home: CompleteSeriesPage(
          series: _series(),
          searchBooks: (_) => pending.future,
        ),
      ),
    );
    expect(find.byType(CardListSkeleton), findsOneWidget);

    pending.completeError(
      const ApiException(statusCode: 500, message: 'Error simulado'),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Error simulado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _DialogHarness extends StatelessWidget {
  const _DialogHarness({
    required this.book,
    this.preservePersonalData = false,
    this.initialStatus = 'PENDIENTE',
    this.onResult,
  });

  final CatalogBook book;
  final bool preservePersonalData;
  final String initialStatus;
  final ValueChanged<SeriesVolumeSelection>? onResult;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () async {
              final result = await showModalBottomSheet<SeriesVolumeSelection>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (dialogContext) => DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: .85,
                  minChildSize: .5,
                  maxChildSize: .95,
                  builder: (_, scrollController) => SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SeriesVolumeDetailsDialog(
                        book: book,
                        preservePersonalData: preservePersonalData,
                        initialOrder: '1',
                        initialStatus: initialStatus,
                        initialFormat: '',
                        initialRating: '',
                        initialStartDate: null,
                        initialEndDate: null,
                      ),
                    ),
                  ),
                ),
              );
              if (result != null) onResult?.call(result);
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
}

CatalogBook _book({
  required bool inLibrary,
  String status = 'PENDIENTE',
  String title = 'El libro',
}) => CatalogBook(
  id: 'book-1',
  source: 'CLUBREADS',
  title: title,
  authors: const [],
  coverUrl: '',
  genre: '',
  isbn: '',
  inMyLibrary: inLibrary,
  status: status,
);

PerfilSaga _series() => PerfilSaga.fromJson(const {
  'id': 'saga-1',
  'nombre': 'Saga de prueba',
  'autor': '',
  'estado': 'PENDIENTE',
  'volumenes': [],
});
