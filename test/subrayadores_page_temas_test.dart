import 'package:club_lectura_app/models/subrayador_categoria.dart';
import 'package:club_lectura_app/pages/subrayadores_page.dart';
import 'package:club_lectura_app/services/categorias_comentario_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _pagina() => const MaterialApp(
  home: SubrayadoresPage(
    libro: 'Libro',
    coverUrl: '',
    colores: [
      Color(0xFFD62839),
      Color(0xFF141416),
      Color(0xFFF9D71C),
      Color(0xFF5DBB63),
      Color(0xFF7B1E2E),
    ],
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CategoriasComentarioService.reiniciar();
  });

  Future<void> prepararPantalla(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets(
    'sin personalizar se ven los temas de siempre con su descripción',
    (tester) async {
      await prepararPantalla(tester);
      await tester.pumpWidget(_pagina());
      await tester.pumpAndSettle();

      expect(find.text('Personajes'), findsOneWidget);
      expect(find.text('Detalles importantes del mundo.'), findsOneWidget);
      expect(find.text('Impacto'), findsOneWidget);
    },
  );

  testWidgets('con temas propios la propuesta muestra esos mismos nombres', (
    tester,
  ) async {
    await CategoriasComentarioService.guardar([
      for (var i = 0; i < kSubrayadorCategorias.length; i++)
        i == 3
            ? const SubrayadorCategoria(
                emoji: '🎭',
                nombre: 'Villanos',
                esCita: false,
              )
            : kSubrayadorCategorias[i],
    ]);
    await prepararPantalla(tester);
    await tester.pumpWidget(_pagina());
    await tester.pumpAndSettle();

    expect(find.text('🎭 Villanos'), findsOneWidget);
    expect(find.text('Personajes'), findsNothing);
    // El tema renombrado pierde la descripción estándar; los demás la conservan.
    expect(find.text('Detalles importantes del mundo.'), findsNothing);
    expect(find.text('Ideas, sospechas y predicciones.'), findsOneWidget);
  });

  testWidgets('desde aquí también se pueden editar los temas', (tester) async {
    await prepararPantalla(tester);
    await tester.pumpWidget(_pagina());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Editar mis temas'));
    await tester.tap(find.text('Editar mis temas'));
    await tester.pumpAndSettle();

    expect(find.text('Mis temas de subrayado'), findsOneWidget);
  });
}
