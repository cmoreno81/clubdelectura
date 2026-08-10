import 'package:club_lectura_app/models/club_membership.dart';
import 'package:club_lectura_app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const club = ClubMembership(
    id: 'club-1',
    nombre: 'Club de prueba',
    slug: 'club-prueba',
    rol: 'MEMBER',
    activo: true,
  );

  testWidgets('al abrir el club solo construye el dashboard', (tester) async {
    final builds = List<int>.filled(5, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          club: club,
          pageBuilders: [
            for (var index = 0; index < 5; index++)
              () {
                builds[index]++;
                return Text('página $index');
              },
          ],
        ),
      ),
    );

    expect(builds, [1, 0, 0, 0, 0]);
    expect(find.text('página 0'), findsOneWidget);
  });

  testWidgets('cada pestaña se inicializa una sola vez al visitarla', (
    tester,
  ) async {
    final builds = List<int>.filled(5, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          club: club,
          pageBuilders: [
            for (var index = 0; index < 5; index++)
              () {
                builds[index]++;
                return Text('página $index');
              },
          ],
        ),
      ),
    );

    for (final label in ['Libros', 'Sagas', 'Lecturas', 'Clubvisión']) {
      await tester.tap(find.text(label));
      await tester.pump();
    }
    for (final label in [
      'El Club',
      'Libros',
      'Sagas',
      'Lecturas',
      'Clubvisión',
    ]) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    expect(builds, [1, 1, 1, 1, 1]);
  });

  testWidgets('una pestaña visitada conserva su estado al quedar oculta', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          club: club,
          pageBuilders: [
            () => const Text('dashboard'),
            () => _StatefulTab(scrollController: scrollController),
            () => const Text('sagas'),
            () => const Text('lecturas'),
            () => const Text('clubvisión'),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Libros'));
    await tester.pump();
    await tester.tap(find.text('incrementar'));
    await tester.pump();
    expect(find.text('valor 1'), findsOneWidget);
    scrollController.jumpTo(300);
    await tester.pump();

    await tester.tap(find.text('El Club'));
    await tester.pump();
    await tester.tap(find.text('Libros'));
    await tester.pump();

    expect(scrollController.offset, 300);
    scrollController.jumpTo(0);
    await tester.pump();
    expect(find.text('valor 1'), findsOneWidget);
  });
}

class _StatefulTab extends StatefulWidget {
  const _StatefulTab({required this.scrollController});

  final ScrollController scrollController;

  @override
  State<_StatefulTab> createState() => _StatefulTabState();
}

class _StatefulTabState extends State<_StatefulTab> {
  var value = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      children: [
        Text('valor $value'),
        TextButton(
          onPressed: () => setState(() => value++),
          child: const Text('incrementar'),
        ),
        for (var index = 0; index < 50; index++)
          SizedBox(height: 40, child: Text('elemento $index')),
      ],
    );
  }
}
