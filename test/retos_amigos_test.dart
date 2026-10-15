import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:club_lectura_app/models/amistad.dart';
import 'package:club_lectura_app/widgets/amistades/retos_amigos.dart';

const _marta = PersonaAmistad(nombre: 'Marta');
const _irene = PersonaAmistad(nombre: 'Irene');

RetoAmigos _reto({bool invitada = false, int total = 3}) => RetoAmigos(
  id: 'r1',
  titulo: 'Retazo',
  objetivo: 6,
  total: total,
  invitada: invitada,
  conseguido: total >= 6,
  personas: const [
    PersonaReto(nombre: 'Yo', yo: true, aceptado: true, libros: 2),
    PersonaReto(nombre: 'Marta', aceptado: true, libros: 1),
    PersonaReto(nombre: 'Irene'),
  ],
);

Widget _app(Widget hijo) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: hijo)),
);

void main() {
  testWidgets('reto: una barra común, aportación de cada una y pendientes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        RetosAmigosSeccion(
          amistades: const [_marta],
          cargar: () async => [_reto()],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retazo'), findsOneWidget);
    expect(find.text('3 de 6 libros entre todas'), findsOneWidget);
    expect(find.text('Tú · 2'), findsOneWidget);
    expect(find.text('Marta · 1'), findsOneWidget);
    expect(find.text('Irene · pendiente'), findsOneWidget);
    final barra = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(barra.value, 0.5);
  });

  testWidgets('reto conseguido se celebra', (tester) async {
    await tester.pumpWidget(
      _app(
        RetosAmigosSeccion(
          amistades: const [_marta],
          cargar: () async => [_reto(total: 7)],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Lo habéis conseguido'), findsOneWidget);
  });

  testWidgets('una propuesta se acepta o se rechaza desde la tarjeta', (
    tester,
  ) async {
    final respuestas = <String>[];
    await tester.pumpWidget(
      _app(
        RetosAmigosSeccion(
          amistades: const [_marta],
          cargar: () async => [_reto(invitada: true)],
          responder: (id, aceptar) async {
            respuestas.add('$id:$aceptar');
            return const ResultadoAmistad(ok: true);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reto-salir-r1')), findsNothing);
    expect(find.text('Marta y Irene te proponen leer 6 libros entre todas.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reto-aceptar-r1')));
    await tester.pumpAndSettle();
    expect(respuestas, ['r1:true']);
  });

  testWidgets(
    'crear un reto: pide al menos una amiga y envía nombre, meta y periodo',
    (tester) async {
      Map<String, Object?>? enviado;
      await tester.pumpWidget(
        _app(
          RetosAmigosSeccion(
            amistades: const [_marta, _irene],
            cargar: () async => const [],
            crear:
                ({
                  required titulo,
                  required objetivo,
                  required periodo,
                  required nombres,
                }) async {
                  enviado = {
                    't': titulo,
                    'o': objetivo,
                    'p': periodo,
                    'n': nombres,
                  };
                  return const ResultadoAmistad(ok: true);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reto-crear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reto-enviar')));
      await tester.pumpAndSettle();
      expect(find.text('Elige al menos a una amiga.'), findsOneWidget);
      expect(enviado, isNull);

      await tester.tap(find.byKey(const Key('reto-mas')));
      await tester.tap(find.byKey(const Key('reto-amiga-Irene')));
      await tester.tap(find.text('Este año'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reto-enviar')));
      await tester.pumpAndSettle();
      expect(enviado, {
        't': 'Nuestro reto',
        'o': 6,
        'p': 'ANO',
        'n': ['Irene'],
      });
    },
  );

  testWidgets('sin amistades ni retos la sección no sale', (tester) async {
    await tester.pumpWidget(
      _app(RetosAmigosSeccion(cargar: () async => const [])),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('amigos-retos')), findsNothing);
  });

  testWidgets(
    'rachas juntas: días seguidos y a quién le toca hoy; vacío no sale',
    (tester) async {
      await tester.pumpWidget(
        _app(
          RachasCompartidasSeccion(
            cargar: () async => const [
              RachaCompartida(nombre: 'Marta', dias: 5, ellaHoy: true),
              RachaCompartida(
                nombre: 'Irene',
                dias: 2,
                yoHoy: true,
                ellaHoy: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('🔥 5 días'), findsOneWidget);
      expect(find.text('Hoy ya ha leído Marta: te toca'), findsOneWidget);
      expect(find.text('Hoy habéis leído las dos'), findsOneWidget);

      await tester.pumpWidget(
        _app(
          RachasCompartidasSeccion(
            key: UniqueKey(),
            cargar: () async => const [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('amigos-rachas')), findsNothing);
    },
  );
}
