import 'package:club_lectura_app/models/catalog_book.dart';
import 'package:club_lectura_app/pages/explore_catalog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CatalogBook _libro(
  String id,
  String titulo, {
  String origen = 'CLUBREADS',
  int? lectores,
}) => CatalogBook(
  id: id,
  source: origen,
  title: titulo,
  authors: const ['Suzanne Collins'],
  coverUrl: '',
  genre: '',
  isbn: '',
  inMyLibrary: false,
  status: '',
  readers: lectores,
);

Future<void> _abrir(WidgetTester tester, List<CatalogBook> resultados) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ExploreCatalogPage(
        initialQuery: 'en llamas',
        cargarBusqueda: (_) async => resultados,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'lo que ya está en ClubReads va primero, destacado y con sus lectores',
    (tester) async {
      await _abrir(tester, [
        _libro('g1', 'El Mármara en llamas', origen: 'GOOGLE'),
        _libro('c1', 'En llamas', lectores: 5),
        _libro('c2', 'Sinsajo', lectores: 1),
      ]);
      expect(find.text('En ClubReads (2)'), findsOneWidget);
      expect(find.text('Otros resultados'), findsOneWidget);
      // Una pastilla llena «En ClubReads» por cada libro de ClubReads (más el título de la cabecera).
      expect(find.text('En ClubReads'), findsNWidgets(2));
      expect(find.text('5 lectores'), findsOneWidget);
      expect(find.text('1 lector'), findsOneWidget);
      expect(find.text('Google Books'), findsOneWidget);
      // El orden: la cabecera de ClubReads sale antes que la de lo externo.
      final yClub = tester.getTopLeft(find.text('En ClubReads (2)')).dy;
      final yOtros = tester.getTopLeft(find.text('Otros resultados')).dy;
      expect(yClub < yOtros, isTrue);
    },
  );

  testWidgets(
    'si no hay nada en ClubReads se dice que se creará una ficha nueva',
    (tester) async {
      await _abrir(tester, [
        _libro('g1', 'El Mármara en llamas', origen: 'GOOGLE'),
      ]);
      expect(find.textContaining('En ClubReads ('), findsNothing);
      expect(
        find.text('Aún no está en ClubReads: al añadirlo se crea su ficha.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'antes de crear una ficha externa, si hay resultados de ClubReads, se pregunta',
    (tester) async {
      await _abrir(tester, [
        _libro('c1', 'En llamas', lectores: 5),
        _libro('g1', 'Los Juegos del Hambre 2 - En llamas', origen: 'GOOGLE'),
      ]);
      await tester.tap(find.byTooltip('Crear ficha y añadir a mi biblioteca'));
      await tester.pumpAndSettle();
      expect(find.text('¿Seguro que no está ya en ClubReads?'), findsOneWidget);
      await tester.tap(find.text('Mirar los de ClubReads'));
      await tester.pumpAndSettle();
      // No se ha creado nada: no hay hoja de añadir ni rueda de carga.
      expect(find.text('¿Seguro que no está ya en ClubReads?'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
