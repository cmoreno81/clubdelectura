import 'package:club_lectura_app/widgets/libros/buscador_casa_del_libro_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'el buscador pide al menos dos letras y abre la búsqueda con el enlace de afiliado',
    (tester) async {
      final pedidos = <String>[];
      final abiertos = <Uri>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuscadorCasaDelLibroCard(
              obtenerUrl: (q) async {
                pedidos.add(q);
                return 'https://www.awin1.com/cread.php?ued=x';
              },
              abrir: (u) async {
                abiertos.add(u);
                return true;
              },
            ),
          ),
        ),
      );
      expect(find.text('¿No encuentras lo que buscas?'), findsOneWidget);
      expect(find.text('Publicidad'), findsOneWidget);

      await tester.tap(find.byKey(const Key('buscador-casa-del-libro-buscar')));
      await tester.pump();
      expect(
        find.text('Escribe el título o la autoría que buscas.'),
        findsOneWidget,
      );
      expect(pedidos, isEmpty);

      await tester.enterText(
        find.byKey(const Key('buscador-casa-del-libro-texto')),
        '  Los leones de Al rassan ',
      );
      await tester.tap(find.byKey(const Key('buscador-casa-del-libro-buscar')));
      await tester.pumpAndSettle();
      expect(pedidos, ['Los leones de Al rassan']);
      expect(abiertos.single.host, 'www.awin1.com');
      expect(
        find.text('Escribe el título o la autoría que buscas.'),
        findsNothing,
      );
    },
  );

  testWidgets('si no se puede abrir la tienda lo dice', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuscadorCasaDelLibroCard(
            obtenerUrl: (_) async => null,
            abrir: (_) async => true,
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('buscador-casa-del-libro-texto')),
      'dune',
    );
    await tester.tap(find.byKey(const Key('buscador-casa-del-libro-buscar')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No se ha podido abrir la tienda'),
      findsOneWidget,
    );
  });
}
