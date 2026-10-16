import 'dart:async';

import 'package:club_lectura_app/models/amistad.dart';
import 'package:club_lectura_app/navigation/app_page_route.dart';
import 'package:club_lectura_app/pages/lista_amigos_page.dart';
import 'package:club_lectura_app/widgets/tablet/detalle_lateral.dart';
import 'package:club_lectura_app/widgets/tablet/marco_tablet.dart';
import 'package:club_lectura_app/widgets/tablet/shell_navegacion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    DetalleLateral.instance.cerrar();
    ShellNavegacion.instance.liberar('prueba');
  });

  testWidgets('iPad ancho: Inicio → lista de amigos → ficha en el panel', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1376, 1032);
    addTearDown(tester.view.reset);
    var seleccionado = -1;
    ShellNavegacion.instance.registrar(
      'prueba',
      alSeleccionar: (i) => seleccionado = i,
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MarcoTablet(child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                AppPageRoute(
                  builder: (_) => ListaAmigosPage(
                    amistades: const [PersonaAmistad(nombre: 'Cristina')],
                  ),
                ),
              ),
              child: const Text('ir'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ir'));
    await tester.pumpAndSettle();
    expect(find.text('Tus amigos'), findsOneWidget);

    // Pulsar a la amiga abre su ficha en el panel (aquí, una pantalla simple).
    final ctx = tester.element(find.text('Cristina'));
    unawaited(
      empujarDetalle<void>(
        ctx,
        AppPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Perfil de Cristina')),
            body: const Text('contenido del perfil'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('panel-detalle')), findsOneWidget);
    expect(find.text('contenido del perfil'), findsOneWidget);

    // La flecha de la ficha cierra el panel.
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('panel-detalle')), findsNothing);

    // Se vuelve a abrir y la X lo cierra.
    unawaited(
      empujarDetalle<void>(
        ctx,
        AppPageRoute(builder: (_) => const Scaffold(body: Text('otra'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('panel-detalle')), findsOneWidget);
    await tester.tap(find.byKey(const Key('panel-detalle-cerrar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('panel-detalle')), findsNothing);

    // Con el panel abierto, la flecha de la lista vuelve y la barra lateral
    // sigue funcionando.
    unawaited(
      empujarDetalle<void>(
        ctx,
        AppPageRoute(builder: (_) => const Scaffold(body: Text('otra'))),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('barra-lateral-2')));
    await tester.pumpAndSettle();
    expect(seleccionado, 2);
    expect(find.byKey(const Key('panel-detalle')), findsNothing);
  });
}
