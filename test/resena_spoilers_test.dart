import 'package:club_lectura_app/models/perfil_usuario.dart';
import 'package:club_lectura_app/widgets/libros/finalizar_libro_dialog.dart';
import 'package:club_lectura_app/widgets/perfil/editar_fechas_lectura_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Map<String, String>?> _abrir(
  WidgetTester tester,
  Future<Map<String, String>?> Function(BuildContext) abrir,
) async {
  Map<String, String>? resultado;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async => resultado = await abrir(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return Future.value(resultado);
}

void main() {
  testWidgets(
    'al terminar un libro se puede marcar que la reseña contiene spoilers',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Map<String, String>? resultado;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async =>
                      resultado = await FinalizarLibroDialog.show(
                        context,
                        formatoActual: 'PAPEL',
                      ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Mi reseña contiene spoilers'), findsOneWidget);
      await tester.tap(find.text('No era para mí')); // elige una valoración
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Se muere al final');
      await tester.tap(find.text('Mi reseña contiene spoilers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finalizar'));
      await tester.pumpAndSettle();

      expect(resultado?['reflexion'], 'Se muere al final');
      expect(resultado?['contieneSpoilers'], 'true');
    },
  );

  testWidgets('sin tocar el interruptor, la reseña no cuenta como spoiler', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Map<String, String>? resultado;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async =>
                    resultado = await FinalizarLibroDialog.show(
                      context,
                      formatoActual: 'PAPEL',
                    ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No era para mí'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    expect(resultado?['contieneSpoilers'], 'false');
  });

  test(
    'el estado de spoilers de una lectura terminada se lee del servidor',
    () {
      final l = PerfilLibroTerminado.fromJson({
        'libro': 'X',
        'resena': 'Texto',
        'contieneSpoilers': true,
      });
      expect(l.contieneSpoilers, isTrue);
      expect(
        PerfilLibroTerminado.fromJson({'libro': 'X'}).contieneSpoilers,
        isFalse,
      );
    },
  );

  testWidgets(
    'editar una lectura terminada enseña el interruptor como está guardado',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditarFechasLecturaDialog(
              libro: PerfilLibroTerminado.fromJson({
                'libro': 'X',
                'fechaInicio': '2026-10-01',
                'fechaFin': '2026-10-05',
                'valoracion': '4',
                'resena': 'Texto',
                'contieneSpoilers': true,
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final interruptor = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(interruptor.value, isTrue);
    },
  );
}
