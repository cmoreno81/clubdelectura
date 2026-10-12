import 'package:club_lectura_app/models/capitulo_lectura.dart';
import 'package:club_lectura_app/widgets/lectura/capitulo_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CapituloLectura _capitulo(Map<String, dynamic> extra) =>
    CapituloLectura.fromJson({'nombre': 'Capítulo 6', ...extra});

void main() {
  test('CapituloLectura lee si está cerrado y cuándo se abre', () {
    final cerrado = _capitulo({
      'bloqueado': true,
      'desbloqueaEl': '2026-10-21',
    });
    expect(cerrado.bloqueado, isTrue);
    expect(cerrado.desbloqueaEl, '2026-10-21');
    expect(_capitulo({}).bloqueado, isFalse);
  });

  testWidgets('un capítulo cerrado enseña el candado, la fecha y no se abre', (
    tester,
  ) async {
    var abierto = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CapituloTile(
            capitulo: _capitulo({
              'bloqueado': true,
              'desbloqueaEl': '2026-10-21',
            }),
            plegado: false,
            onTap: () => abierto = true,
            onTogglePlegado: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.textContaining('Se abre el'), findsOneWidget);
    expect(find.textContaining('21 oct'), findsOneWidget);

    await tester.tap(find.text('Capítulo 6'));
    await tester.pump();
    expect(abierto, isFalse);
  });

  testWidgets('un capítulo abierto se comporta como siempre', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CapituloTile(
              capitulo: _capitulo({}),
              plegado: false,
              onTap: () {},
              onTogglePlegado: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
  });
}
