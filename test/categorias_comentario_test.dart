import 'package:club_lectura_app/models/comentario_lectura.dart';
import 'package:club_lectura_app/models/subrayador_categoria.dart';
import 'package:club_lectura_app/pages/paleta_lectura_page.dart';
import 'package:club_lectura_app/services/categorias_comentario_service.dart';
import 'package:club_lectura_app/widgets/common/editor_categorias_sheet.dart';
import 'package:club_lectura_app/widgets/lectura/comentario_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<SubrayadorCategoria> _conVillanos() => [
  for (var i = 0; i < kSubrayadorCategorias.length; i++)
    i == 3
        ? SubrayadorCategoria(
            emoji: '🎭',
            nombre: 'Villanos',
            esCita: kSubrayadorCategorias[i].esCita,
          )
        : kSubrayadorCategorias[i],
];

ComentarioLectura _comentario({
  required String tipo,
  String etiqueta = '',
  String texto = 'Un comentario',
}) => ComentarioLectura.fromJson({
  'id': 'c1',
  'libro': 'Libro',
  'capitulo': 'Capítulo 1',
  'usuario': 'Lectora',
  'fecha': '2026-10-10T10:00:00.000Z',
  'comentario': texto,
  'tipo': tipo,
  'color': '#C94F7C',
  'etiqueta': etiqueta,
});

Widget _tarjeta(ComentarioLectura comentario) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: ComentarioCard(
        comentario: comentario,
        usuarioActual: 'Otra',
        onActualizar: () {},
      ),
    ),
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CategoriasComentarioService.reiniciar();
  });

  test('sin personalizar se usan las categorías de siempre', () {
    expect(CategoriasComentarioService.categorias.value, kSubrayadorCategorias);
    expect(CategoriasComentarioService.estaPersonalizado, isFalse);
  });

  test(
    'guardar cambia los nombres, los recuerda y la cita sigue siendo cita',
    () async {
      final ok = await CategoriasComentarioService.guardar(_conVillanos());
      expect(ok, isTrue);

      final guardadas = CategoriasComentarioService.categorias.value;
      expect(guardadas[3].nombre, 'Villanos');
      expect(guardadas[3].emoji, '🎭');
      expect(CategoriasComentarioService.estaPersonalizado, isTrue);
      // La tercera categoría es la cita y no se puede cambiar.
      expect(guardadas.map((c) => c.esCita), [
        false,
        false,
        true,
        false,
        false,
      ]);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('categorias_comentario_anonymous'),
        contains('Villanos'),
      );
    },
  );

  test('un nombre vacío no se guarda', () async {
    final invalidas = [
      for (final c in kSubrayadorCategorias)
        SubrayadorCategoria(emoji: c.emoji, nombre: '  ', esCita: c.esCita),
    ];
    expect(await CategoriasComentarioService.guardar(invalidas), isFalse);
    expect(CategoriasComentarioService.categorias.value, kSubrayadorCategorias);
  });

  test('restablecer vuelve a los nombres de siempre', () async {
    await CategoriasComentarioService.guardar(_conVillanos());
    await CategoriasComentarioService.restablecer();
    expect(CategoriasComentarioService.categorias.value, kSubrayadorCategorias);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('categorias_comentario_anonymous'), isNull);
  });

  test('el comentario trae la etiqueta de su autora y un libre no', () {
    expect(
      _comentario(tipo: 'PERSONAJE', etiqueta: '🎭 Villanos').etiqueta,
      '🎭 Villanos',
    );
    expect(
      ComentarioLectura.fromJson({'id': 'x', 'comentario': 'hola'}).etiqueta,
      isEmpty,
    );
    expect(
      _comentario(
        tipo: 'PERSONAJE',
        etiqueta: '🎭 Villanos',
      ).copyWith(comentario: 'Editado').etiqueta,
      '🎭 Villanos',
    );
  });

  testWidgets('los demás ven el nombre que puso la autora', (tester) async {
    await tester.pumpWidget(
      _tarjeta(_comentario(tipo: 'PERSONAJE', etiqueta: '🎭 Villanos')),
    );
    expect(find.text('🎭 Villanos'), findsOneWidget);
    expect(find.text('🧩 Personaje'), findsNothing);
  });

  testWidgets('sin etiqueta se ve el nombre estándar', (tester) async {
    await tester.pumpWidget(_tarjeta(_comentario(tipo: 'PERSONAJE')));
    expect(find.text('🧩 Personaje'), findsOneWidget);
  });

  testWidgets('una cita renombrada sigue mostrándose como cita', (
    tester,
  ) async {
    await tester.pumpWidget(
      _tarjeta(
        _comentario(
          tipo: 'QUOTE',
          etiqueta: '🗣️ Frases',
          texto: 'Frase buena',
        ),
      ),
    );
    expect(find.text('🗣️ Frases'), findsOneWidget);
    expect(find.text('Cita del libro'), findsNothing);
    // El formato de cita (entre comillas) se mantiene.
    expect(find.text('“Frase buena”'), findsOneWidget);
  });

  testWidgets('el editor permite renombrar los temas y guardarlos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => mostrarEditorCategorias(context),
              child: const Text('editar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('editar'));
    await tester.pumpAndSettle();

    // El cuarto tema («Personaje») pasa a llamarse «Villanos».
    final campos = find.byType(TextField);
    expect(campos, findsNWidgets(10));
    await tester.enterText(campos.at(7), 'Villanos');
    await tester.pump();
    await tester.tap(find.text('Guardar mis temas'));
    await tester.pumpAndSettle();

    expect(CategoriasComentarioService.categorias.value[3].nombre, 'Villanos');
    expect(find.text('Tus temas se han guardado'), findsOneWidget);
  });

  testWidgets('el editor no deja guardar con un nombre vacío', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => mostrarEditorCategorias(context),
              child: const Text('editar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('editar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '');
    await tester.pump();

    final boton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Guardar mis temas'),
    );
    expect(boton.onPressed, isNull);
  });

  testWidgets('la leyenda de la paleta muestra los temas de la lectora', (
    tester,
  ) async {
    await CategoriasComentarioService.guardar(_conVillanos());
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: PaletaLecturaPage(bookId: 'b1', libro: 'Libro'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Editar mis temas'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('🎭 Villanos'), findsOneWidget);
    expect(find.text('Mundo y personajes'), findsNothing);
    // Un tema con nombre propio no conserva la descripción estándar.
    expect(find.text('Detalles importantes de la historia'), findsNothing);
    // Los que no se tocaron siguen igual.
    expect(find.text('Teorías'), findsOneWidget);
  });
}
