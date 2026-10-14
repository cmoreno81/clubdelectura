import 'package:club_lectura_app/models/amistad.dart';
import 'package:club_lectura_app/widgets/amistades/comentarios_progreso.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _datos = ComentariosProgresoData(
  titulo: 'Yesteryear',
  comentarios: [
    ComentarioProgreso(
      id: 'c1',
      autor: 'Lucía',
      texto: '¡Qué ganas de leerlo!',
      puedoBorrar: false,
    ),
    ComentarioProgreso(
      id: 'c2',
      autor: 'Cris M.',
      texto: 'Ya voy por la mitad',
      esMio: true,
      puedoBorrar: true,
    ),
  ],
);

Widget _hoja({
  Future<ComentariosProgresoData> Function(String)? cargar,
  Future<ResultadoAmistad> Function(String, String)? enviar,
  Future<ResultadoAmistad> Function(String)? borrar,
  Future<bool> Function(String, String)? reportar,
}) => MaterialApp(
  home: Scaffold(
    body: ComentariosProgresoSheet(
      libraryId: 'l1',
      titulo: 'Yesteryear',
      cargar: cargar ?? (_) async => _datos,
      enviar: enviar,
      borrar: borrar,
      reportar: reportar,
    ),
  ),
);

void main() {
  test('los comentarios del servidor se leen con quién puede borrar', () {
    final d = ComentariosProgresoData.fromJson({
      'titulo': 'X',
      'soyDuena': true,
      'comentarios': [
        {'id': 'a', 'autor': 'Lucía', 'texto': 'hola', 'puedoBorrar': true},
      ],
    });
    expect(d.soyDuena, isTrue);
    expect(d.comentarios.single.puedoBorrar, isTrue);
    expect(d.comentarios.single.esMio, isFalse);
  });

  testWidgets(
    'enseña los comentarios y ofrece reportar o bloquear solo los ajenos',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_hoja());
      await tester.pumpAndSettle();
      expect(find.text('¡Qué ganas de leerlo!'), findsOneWidget);
      expect(find.text('Cris M. (tú)'), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      expect(find.text('Reportar'), findsOneWidget);
      expect(find.text('Bloquear'), findsOneWidget);
      expect(find.text('Borrar'), findsNothing);
    },
  );

  testWidgets('comentar envía el texto y recarga; reportar manda el motivo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final enviados = <String>[];
    var cargas = 0;
    String? reportado;
    await tester.pumpWidget(
      _hoja(
        cargar: (_) async {
          cargas++;
          return _datos;
        },
        enviar: (id, texto) async {
          enviados.add('$id:$texto');
          return const ResultadoAmistad(ok: true);
        },
        reportar: (id, motivo) async {
          reportado = '$id:$motivo';
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Qué bien');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();
    expect(enviados, ['l1:Qué bien']);
    expect(cargas, 2);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reportar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'spam');
    await tester.tap(find.widgetWithText(FilledButton, 'Reportar'));
    await tester.pumpAndSettle();
    expect(reportado, 'c1:spam');
    // El mensaje sale dentro de la hoja (un SnackBar quedaría tapado por ella).
    expect(find.text('Gracias, lo revisaremos en breve.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    // Y se quita solo.
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Gracias, lo revisaremos en breve.'), findsNothing);
  });

  testWidgets('si no hay acceso o falla, lo dice sin romperse', (tester) async {
    await tester.pumpWidget(
      _hoja(cargar: (_) async => throw Exception('servidor antiguo')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No se han podido cargar'), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsNothing);
  });
}
