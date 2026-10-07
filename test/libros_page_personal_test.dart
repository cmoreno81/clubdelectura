import 'package:club_lectura_app/models/libro.dart';
import 'package:club_lectura_app/models/libros_data.dart';
import 'package:club_lectura_app/pages/libros_page.dart';
import 'package:club_lectura_app/services/atmosfera_controller.dart';
import 'package:club_lectura_app/services/atmosfera_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Libro _libro(String titulo, {required String usuario, required bool mio}) =>
    Libro(
      bookId: titulo,
      usuario: usuario,
      libro: titulo,
      genero: 'Fantasía',
      saga: '',
      numSaga: '',
      autoconclusivo: 'SI',
      prioridad: '',
      estado: 'PENDIENTE',
      valoracion: '',
      yaLoTengo: mio,
      goodreads: '',
      coverUrl: '',
      fechaAlta: null,
      startedAt: null,
      pausedAt: null,
      pauseReason: '',
      avatarUrl: '',
      paginas: null,
    );

void main() {
  testWidgets(
    'Mi biblioteca muestra mis libros por la marca del servidor, no por el '
    'nombre guardado en la sesión, y no los de otras lectoras',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'screen_hint_v1_hint_biblioteca_v1': true,
      });
      final atmosfera = AtmosferaController();
      await tester.pumpWidget(
        AtmosferaScope(
          controller: atmosfera,
          child: MaterialApp(
            home: LibrosPage(
              esPersonal: true,
              loadData: () async => LibrosData(
                libros: [
                  _libro('Mi libro', usuario: 'Cris M.', mio: true),
                  _libro('Libro de otra', usuario: 'Susana', mio: false),
                ],
                finalizados: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mi libro'), findsWidgets);
      expect(find.text('Libro de otra'), findsNothing);
      atmosfera.dispose();
    },
  );
}
