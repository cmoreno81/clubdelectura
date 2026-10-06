import 'package:club_lectura_app/widgets/common/ancla_de_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Prueba extends StatefulWidget {
  const _Prueba({required this.conAncla});
  final bool conAncla;

  @override
  State<_Prueba> createState() => _PruebaState();
}

class _PruebaState extends State<_Prueba> {
  double alto = 0;

  @override
  Widget build(BuildContext context) {
    final bloque = SizedBox(
      height: alto,
      child: const ColoredBox(color: Colors.red),
    );
    return MaterialApp(
      home: Scaffold(
        // Misma estructura que la ficha del libro: scroll normal con Column.
        body: SingleChildScrollView(
          key: const Key('lista'),
          child: Column(
            children: [
              widget.conAncla ? AnclaDeScroll(child: bloque) : bloque,
              for (var i = 0; i < 40; i++)
                SizedBox(height: 100, child: Text('$i')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => setState(() => alto = 300),
        ),
      ),
    );
  }
}

void main() {
  Future<double> offsetTrasCrecer(WidgetTester tester, bool conAncla) async {
    await tester.pumpWidget(_Prueba(conAncla: conAncla));
    final lista = tester.state<ScrollableState>(find.byType(Scrollable));
    lista.position.jumpTo(500); // el usuario ya ha bajado
    await tester.pump();
    await tester.tap(find.byType(FloatingActionButton)); // el bloque de arriba crece 300 px
    await tester.pumpAndSettle();
    return lista.position.pixels;
  }

  testWidgets('sin ancla, un bloque que crece arriba desplaza lo que lees', (tester) async {
    expect(await offsetTrasCrecer(tester, false), 500);
  });

  testWidgets('con ancla, la posición se corrige para que no se note el salto', (tester) async {
    expect(await offsetTrasCrecer(tester, true), 800);
  });
}
