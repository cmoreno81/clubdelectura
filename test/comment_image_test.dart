import 'dart:convert';
import 'dart:typed_data';

import 'package:club_lectura_app/models/comentario_lectura.dart';
import 'package:club_lectura_app/services/foto_comentario_service.dart';
import 'package:club_lectura_app/widgets/lectura/comentario_card.dart';
import 'package:club_lectura_app/widgets/lectura/comentario_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// PNG de 1×1 px, suficiente para que Image.memory no falle.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

ComentarioLectura _comentario({
  String texto = 'Mira esto',
  String imagen = '',
}) => ComentarioLectura.fromJson({
  'id': 'c1',
  'libro': 'Libro',
  'capitulo': 'Capítulo 1',
  'usuario': 'Lectora',
  'fecha': '2026-10-10T10:00:00.000Z',
  'comentario': texto,
  'imagenUrl': imagen,
});

void main() {
  test('un comentario con foto la expone y la conserva al editarlo', () {
    final comentario = _comentario(
      imagen: 'https://res.cloudinary.com/x/a.jpg',
    );
    expect(comentario.tieneImagen, isTrue);
    expect(
      comentario.copyWith(comentario: 'Editado').imagenUrl,
      comentario.imagenUrl,
    );
  });

  test('un comentario antiguo del servidor no trae foto', () {
    final comentario = ComentarioLectura.fromJson({
      'id': 'old',
      'comentario': 'Hola',
    });
    expect(comentario.tieneImagen, isFalse);
    expect(comentario.imagenUrl, isEmpty);
  });

  test('la foto se envía como data URL JPEG y se rechaza si pasa de 3 MB', () {
    final pequena = FotoComentario.desdeBytes(Uint8List.fromList([1, 2, 3]));
    expect(pequena.dataUrl, startsWith('data:image/jpeg;base64,'));
    expect(pequena.cabe, isTrue);
    final grande = FotoComentario.desdeBytes(
      Uint8List(FotoComentario.maxBytes + 1),
    );
    expect(grande.cabe, isFalse);
  });

  Widget envolver(Widget hijo) => MaterialApp(home: Scaffold(body: hijo));

  testWidgets('el editor ofrece añadir foto y deja publicar solo con foto', (
    tester,
  ) async {
    final controller = TextEditingController();
    var adjuntar = 0;
    var quitar = 0;
    var enviar = 0;

    Widget editor(Uint8List? foto) => envolver(
      ComentarioInput(
        controller: controller,
        onEnviar: () => enviar++,
        enviando: false,
        hintText: 'Comenta',
        fotoAdjunta: foto,
        onAdjuntarFoto: () => adjuntar++,
        onQuitarFoto: () => quitar++,
      ),
    );

    await tester.pumpWidget(editor(null));
    expect(find.text('Añadir foto'), findsOneWidget);
    // Sin texto ni foto no se puede publicar.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Añadir foto'));
    expect(adjuntar, 1);

    await tester.pumpWidget(editor(_png));
    expect(find.text('Añadir foto'), findsNothing);
    expect(find.byTooltip('Quitar foto'), findsOneWidget);
    // Con foto y sin texto sí se puede publicar.
    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(boton.onPressed, isNotNull);
    boton.onPressed!();
    expect(enviar, 1);
    await tester.tap(find.byTooltip('Quitar foto'));
    expect(quitar, 1);
  });

  testWidgets('el comentario muestra su foto y no pinta texto vacío', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      envolver(
        SingleChildScrollView(
          child: ComentarioCard(
            comentario: _comentario(
              texto: '',
              imagen: 'https://res.cloudinary.com/x/a.jpg',
            ),
            usuarioActual: 'Otra',
            onActualizar: () {},
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(RegExp('Foto del comentario')),
      findsOneWidget,
    );
  });
}
