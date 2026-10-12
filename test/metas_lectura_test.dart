import 'package:club_lectura_app/models/configuracion_lectura.dart';
import 'package:club_lectura_app/models/notificacion.dart';
import 'package:club_lectura_app/pages/configurar_lectura_page.dart';
import 'package:club_lectura_app/widgets/lectura/editor_metas.dart';
import 'package:club_lectura_app/widgets/lectura/tarjeta_meta_lectura.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ConfiguracionLectura _config(List<MetaLectura> metas) => ConfiguracionLectura(
  capitulos: 12,
  prologo: false,
  epilogo: false,
  capitulosDisponibles: const [],
  coverUrl: '',
  bookId: 'b1',
  metas: metas,
);

Widget _app(Widget hijo) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: hijo)),
);

void main() {
  test(
    'una lectura sin metas es como siempre y la respuesta antigua se entiende',
    () {
      final c = ConfiguracionLectura.fromJson({
        'capitulos': 10,
        'capitulosDisponibles': [],
      });
      expect(c.metas, isEmpty);
      expect(c.proximaMeta(DateTime(2026, 10, 12)), isNull);
    },
  );

  test('las metas llegan del servidor y se calcula la próxima con su rango', () {
    final c = ConfiguracionLectura.fromJson({
      'capitulos': 12,
      'capitulosDisponibles': [],
      'metas': [
        {'capitulo': 10, 'fecha': '2026-11-01'},
        {'capitulo': 5, 'fecha': '2026-10-18'},
      ],
    });
    expect(c.metas, hasLength(2));
    final primera = c.proximaMeta(DateTime(2026, 10, 12))!;
    expect(primera.meta.capitulo, 5);
    expect(primera.desde, 1);
    // Pasado el día de la primera meta, la siguiente cubre los capítulos 6 a 10.
    final segunda = c.proximaMeta(DateTime(2026, 10, 19))!;
    expect(segunda.meta.capitulo, 10);
    expect(segunda.desde, 6);
    // El mismo día de la meta aún cuenta como próxima.
    expect(c.proximaMeta(DateTime(2026, 10, 18))!.meta.capitulo, 5);
    // Cumplidas todas.
    expect(c.proximaMeta(DateTime(2026, 11, 2)), isNull);
  });

  test('la fecha se escribe en formato legible', () {
    expect(fechaLegible('2026-10-17'), 'sábado 17 oct');
    expect(fechaIso(DateTime(2026, 3, 5)), '2026-03-05');
  });

  testWidgets('la tarjeta no aparece sin metas', (tester) async {
    await tester.pumpWidget(
      _app(TarjetaMetaLectura(config: _config(const []))),
    );
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('la tarjeta anima en positivo y el mismo día invita a comentar', (
    tester,
  ) async {
    final metas = [
      const MetaLectura(capitulo: 5, fecha: '2026-10-18'),
      const MetaLectura(capitulo: 10, fecha: '2026-11-01'),
    ];
    await tester.pumpWidget(
      _app(
        TarjetaMetaLectura(config: _config(metas), hoy: DateTime(2026, 10, 12)),
      ),
    );
    expect(find.text('📖 Próxima meta: los capítulos 1 a 5'), findsOneWidget);
    expect(find.text('Lo comentamos el domingo 18 oct.'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        TarjetaMetaLectura(config: _config(metas), hoy: DateTime(2026, 10, 18)),
      ),
    );
    expect(find.text('💬 Hoy comentamos los capítulos 1 a 5'), findsOneWidget);
    expect(find.text('¡Cuéntanos qué te ha parecido!'), findsOneWidget);

    // Nunca habla de retrasos.
    expect(
      find.textContaining(RegExp('retras|atrasad|tarde', caseSensitive: false)),
      findsNothing,
    );

    await tester.pumpWidget(
      _app(
        TarjetaMetaLectura(config: _config(metas), hoy: DateTime(2026, 12, 1)),
      ),
    );
    expect(
      find.textContaining('Habéis llegado a todas las metas'),
      findsOneWidget,
    );
  });

  testWidgets(
    'el editor es opcional: sin metas lo explica y deja añadir y quitar',
    (tester) async {
      var metas = <MetaLectura>[];
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _app(
            EditorMetas(
              metas: metas,
              capitulos: 12,
              onChanged: (n) => setState(() => metas = n),
            ),
          ),
        ),
      );
      expect(find.textContaining('Sin metas'), findsOneWidget);
      expect(find.text('Añadir una meta'), findsOneWidget);

      // Añadir: elige día en el calendario.
      await tester.tap(find.text('Añadir una meta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(metas, hasLength(1));
      expect(metas.single.capitulo, 5);
      expect(find.textContaining('Sin metas'), findsNothing);

      // Quitar: vuelve a no haber metas.
      await tester.tap(find.byTooltip('Quitar meta'));
      await tester.pumpAndSettle();
      expect(metas, isEmpty);
      expect(find.textContaining('Sin metas'), findsOneWidget);
    },
  );

  test('los avisos nuevos tienen icono y van a la categoría de lecturas', () {
    for (final tipo in [
      'LECTURA_META_PROXIMA',
      'LECTURA_META_HOY',
      'LECTURA_INVITACION',
    ]) {
      expect(
        notificationBadgeCategory(tipo),
        NotificationBadgeCategory.lecturas,
      );
    }
    final invitacion = Notificacion.fromJson({
      'id': 'n1',
      'tipo': 'LECTURA_INVITACION',
      'titulo': 't',
      'mensaje': 'm',
      'leida': false,
      'createdAt': '2026-10-12T09:00:00.000Z',
    });
    expect(invitacion.emoji, '💌');
  });

  testWidgets('configurar la lectura ofrece metas como algo opcional', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: ConfigurarLecturaPage(libro: 'Libro')),
    );
    expect(find.text('Metas (opcional)'), findsOneWidget);
    expect(find.textContaining('Sin metas'), findsOneWidget);
  });

  testWidgets('al editar la lectura salen las metas que ya tiene', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 4200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: ConfigurarLecturaPage(
          libro: 'Libro',
          editando: true,
          capitulosIniciales: 12,
          metasIniciales: [MetaLectura(capitulo: 5, fecha: '2026-10-18')],
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Sin metas'), findsNothing);
    expect(find.text('domingo 18 oct'), findsOneWidget);
  });
}
