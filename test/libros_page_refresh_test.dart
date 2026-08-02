import 'dart:async';

import 'package:club_lectura_app/models/libro.dart';
import 'package:club_lectura_app/models/libros_data.dart';
import 'package:club_lectura_app/pages/libros_page.dart';
import 'package:club_lectura_app/services/atmosfera_controller.dart';
import 'package:club_lectura_app/services/atmosfera_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'muestra un libro nuevo al regresar a Libros sin perder la búsqueda',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = LibrosPageController();
      final atmosfera = AtmosferaController();
      final refreshResult = Completer<LibrosData>();
      var requests = 0;

      Future<LibrosData> loadData() {
        requests++;
        if (requests == 1) {
          return Future.value(_data('Libro antiguo'));
        }
        return refreshResult.future;
      }

      await tester.pumpWidget(
        AtmosferaScope(
          controller: atmosfera,
          child: MaterialApp(
            home: LibrosPage(controller: controller, loadData: loadData),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Libro');
      await tester.pump();

      unawaited(controller.refresh());
      unawaited(controller.refresh());
      await tester.pump();

      expect(requests, 2);
      expect(find.text('Libro antiguo'), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Libro',
      );

      refreshResult.complete(
        LibrosData(
          libros: [_book('Libro antiguo'), _book('Libro nuevo')],
          finalizados: const [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Libro nuevo'), findsWidgets);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Libro',
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);

      atmosfera.dispose();
    },
  );
}

LibrosData _data(String title) =>
    LibrosData(libros: [_book(title)], finalizados: const []);

Libro _book(String title) => Libro(
  bookId: title,
  usuario: 'Susana',
  libro: title,
  genero: 'Fantasía',
  saga: '',
  numSaga: '',
  autoconclusivo: 'SI',
  prioridad: '',
  estado: 'PENDIENTE',
  valoracion: '',
  yaLoTengo: true,
  goodreads: '',
  coverUrl: '',
  fechaAlta: null,
  startedAt: null,
  pausedAt: null,
  pauseReason: '',
  avatarUrl: '',
  paginas: null,
);
