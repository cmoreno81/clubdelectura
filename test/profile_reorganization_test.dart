import 'package:club_lectura_app/models/perfil_usuario.dart';
import 'package:club_lectura_app/pages/perfil_usuario_page.dart';
import 'package:club_lectura_app/widgets/perfil/perfil_timeline_lectura.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra las secciones nuevas en el orden solicitado', (
    tester,
  ) async {
    await _pumpProfile(tester, profile: _profile());
    final labels = [
      'Resumen',
      'Historial',
      'Favoritos',
      'Meses lectores',
      'Logros',
      'Más',
    ];
    final positions = labels
        .map((label) => tester.getTopLeft(find.text(label)).dx)
        .toList();
    for (var index = 1; index < positions.length; index++) {
      expect(positions[index], greaterThan(positions[index - 1]));
    }
    expect(find.text('Timeline'), findsNothing);
    expect(find.text('Finalizados'), findsNothing);
  });

  testWidgets('una cuenta con varios clubes conserva su indicador', (
    tester,
  ) async {
    await _pumpProfile(tester, profile: _profile(clubs: 2));
    expect(find.text('Miembro de 2 clubes'), findsOneWidget);
    expect(find.text('Clubes'), findsOneWidget);
  });

  testWidgets('Resumen conserva solo sus cuatro bloques', (tester) async {
    await _pumpProfile(tester, profile: _profile());
    expect(find.textContaining('Mi biblioteca'), findsOneWidget);
    expect(find.text('Tu historia lectora'), findsOneWidget);
    expect(find.text('Seguimiento de lectura'), findsOneWidget);
    expect(find.text('Géneros favoritos'), findsOneWidget);
    expect(find.text('Libros favoritos'), findsNothing);
    expect(find.byKey(const ValueKey('book-preview-stub')), findsNothing);
    expect(find.textContaining('Wrapped '), findsNothing);
  });

  testWidgets(
    'Géneros favoritos ocupa todo el ancho con uno, varios y muchos chips',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cases = <List<PerfilGenero>>[
        [PerfilGenero(genero: 'Fantasía', total: 1)],
        [
          PerfilGenero(genero: 'Fantasía', total: 2),
          PerfilGenero(genero: 'Romance', total: 1),
        ],
        [
          PerfilGenero(genero: 'Fantasía', total: 12),
          PerfilGenero(genero: 'Romance', total: 11),
          PerfilGenero(genero: 'Thriller', total: 10),
          PerfilGenero(genero: 'Misterio', total: 9),
          PerfilGenero(genero: 'Histórica', total: 8),
          PerfilGenero(genero: 'Aventura', total: 7),
          PerfilGenero(genero: 'Terror', total: 6),
          PerfilGenero(genero: 'Poesía', total: 5),
          PerfilGenero(genero: 'Ensayo', total: 4),
          PerfilGenero(genero: 'Juvenil', total: 3),
          PerfilGenero(genero: 'Biografía', total: 2),
          PerfilGenero(genero: 'Clásicos', total: 1),
        ],
      ];

      for (final genres in cases) {
        await _pumpGenres(
          tester,
          genres: genres,
          textScaler: const TextScaler.linear(1.3),
        );
        final cardSize = tester.getSize(
          find.byKey(const ValueKey('favorite-genres-card')),
        );
        expect(cardSize.width, closeTo(288, 0.01));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('el estado vacío de Géneros favoritos conserva el ancho', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpGenres(
      tester,
      genres: const [],
      textScaler: const TextScaler.linear(1.3),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('favorite-genres-empty'))).width,
      closeTo(288, 0.01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Historial alterna vistas, filtra por año y conserva sagas completadas',
    (tester) async {
      var loads = 0;
      await _pumpProfile(
        tester,
        profile: _profile(),
        initialTab: 'HISTORIAL',
        onLoad: () => loads++,
      );
      expect(find.text('Cronología'), findsOneWidget);
      expect(find.text('Libros'), findsOneWidget);
      expect(find.text('¡Saga completada!'), findsOneWidget);
      expect(loads, 1);

      await tester.tap(find.text('Libros'));
      await tester.pumpAndSettle();
      expect(find.text('Relectura'), findsOneWidget);
      expect(loads, 1);

      await tester.tap(find.byKey(const ValueKey('history-year-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('${DateTime.now().year - 1}').last);
      await tester.pumpAndSettle();
      expect(find.text('Lectura anterior'), findsOneWidget);
      expect(find.text('Relectura actual'), findsNothing);
      expect(loads, 1);

      await tester.tap(find.text('Cronología'));
      await tester.pumpAndSettle();
      final timeline = tester.widget<PerfilTimelineLectura>(
        find.byType(PerfilTimelineLectura),
      );
      expect(timeline.libros.single.libro, 'Lectura anterior');
    },
  );

  testWidgets(
    'editar una relectura propia usa su completionId y conserva Historial',
    (tester) async {
      PerfilLibroTerminado? edited;
      var loads = 0;
      await _pumpProfile(
        tester,
        profile: _profile(),
        initialTab: 'HISTORIAL',
        onLoad: () => loads++,
        onEdit: (book) async => edited = book,
      );
      await tester.tap(find.text('Libros'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Editar fechas'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar fechas'));
      await tester.pumpAndSettle();

      expect(edited?.completionId, 'completion-reread');
      expect(edited?.esRelectura, isTrue);
      expect(loads, 2);
      expect(find.text('Libros'), findsOneWidget);
      expect(find.text('${DateTime.now().year}'), findsWidgets);
      expect(find.byTooltip('Editar fechas'), findsOneWidget);
    },
  );

  testWidgets('un perfil ajeno no muestra acciones de edición', (tester) async {
    await _pumpProfile(
      tester,
      profile: _profile(),
      currentUser: 'Otra persona',
      initialTab: 'HISTORIAL',
    );
    await tester.tap(find.text('Libros'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Editar fechas'), findsNothing);
  });

  testWidgets('Favoritos reúne favoritos, Libro del año y Wrapped', (
    tester,
  ) async {
    await _pumpProfile(tester, profile: _profile(), initialTab: 'FAVORITOS');
    expect(find.text('Mis lecturas especiales'), findsNothing);
    expect(
      find.text('Favoritos, cuadro anual y recuerdos lectores'),
      findsNothing,
    );
    expect(find.text('Libros favoritos'), findsOneWidget);
    expect(find.byKey(const ValueKey('book-preview-stub')), findsOneWidget);
    expect(find.textContaining('Wrapped '), findsOneWidget);
  });

  testWidgets('Sagas ocultas queda accesible desde Más', (tester) async {
    await _pumpProfile(tester, profile: _profile(), initialTab: 'MAS');
    expect(find.text('Sagas ocultas'), findsOneWidget);
    await tester.tap(find.text('Sagas ocultas'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hidden-series-stub')), findsOneWidget);
  });

  testWidgets('una cuenta sin club mantiene el perfil personal completo', (
    tester,
  ) async {
    final profile = _profile(clubs: 0);
    await _pumpProfile(tester, profile: profile);

    expect(find.textContaining('Mi biblioteca'), findsOneWidget);
    expect(find.text('Tu recorrido como lector'), findsOneWidget);
    expect(find.text('Seguimiento de lectura'), findsOneWidget);
    expect(find.text('Géneros favoritos'), findsOneWidget);
    expect(find.textContaining('Miembro de'), findsNothing);
    expect(find.text('Clubes'), findsNothing);
    expect(find.text('Abandonados'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('Relectura actual'), findsWidgets);
    expect(find.text('¡Saga completada!'), findsOneWidget);

    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Libros favoritos'), findsOneWidget);
    expect(find.byKey(const ValueKey('book-preview-stub')), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('una cuenta sin club ni actividad usa estados vacíos normales', (
    tester,
  ) async {
    await _pumpProfile(
      tester,
      profile: _profile(clubs: 0, withActivity: false),
    );
    expect(find.text('Tu recorrido como lector'), findsOneWidget);
    expect(find.text('Todavía no hay géneros favoritos'), findsOneWidget);
    expect(find.textContaining('Miembro de'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no hay historial'), findsOneWidget);

    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Libros favoritos'), findsOneWidget);
    expect(find.byKey(const ValueKey('book-preview-stub')), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el perfil ajeno sin club es consultable y no editable', (
    tester,
  ) async {
    await _pumpProfile(
      tester,
      profile: _profile(clubs: 0),
      currentUser: 'Otra persona',
      initialTab: 'HISTORIAL',
    );
    expect(find.textContaining('Miembro de'), findsNothing);
    await tester.tap(find.text('Libros'));
    await tester.pumpAndSettle();
    expect(find.text('Relectura actual'), findsOneWidget);
    expect(find.byTooltip('Editar fechas'), findsNothing);
    expect(find.text('Más'), findsNothing);
    expect(find.text('Sagas ocultas'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpGenres(
  WidgetTester tester, {
  required List<PerfilGenero> genres,
  required TextScaler textScaler,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 288,
              child: ProfileFavoriteGenresContent(genres: genres),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  required PerfilUsuario profile,
  String currentUser = 'Ada',
  String initialTab = 'RESUMEN',
  VoidCallback? onLoad,
  Future<void> Function(PerfilLibroTerminado book)? onEdit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PerfilUsuarioPage(
        usuario: profile.usuario,
        initialTab: initialTab,
        loadCurrentUser: () async => currentUser,
        loadProfile: () async {
          onLoad?.call();
          return profile;
        },
        onEditReading: onEdit,
        trackingContentBuilder: () =>
            const SizedBox(key: ValueKey('tracking-stub'), height: 20),
        bookOfYearPreviewBuilder: (_, _) =>
            const SizedBox(key: ValueKey('book-preview-stub'), height: 20),
        hiddenSeriesBuilder: () =>
            const SizedBox(key: ValueKey('hidden-series-stub'), height: 20),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

PerfilUsuario _profile({int clubs = 1, bool withActivity = true}) {
  final year = DateTime.now().year;
  final current = _finished(
    title: 'Relectura actual',
    bookId: 'book-current',
    completionId: 'completion-reread',
    year: year,
    reread: true,
  );
  final previous = _finished(
    title: 'Lectura anterior',
    bookId: 'book-previous',
    completionId: 'completion-original',
    year: year - 1,
  );
  return PerfilUsuario(
    usuario: 'Ada',
    avatarUrl: '',
    resumen: PerfilResumen.fromJson({
      'terminados': withActivity ? 2 : 0,
      'relecturas': withActivity ? 1 : 0,
      'clubes': clubs,
    }),
    leyendo: const [],
    terminados: withActivity ? [current, previous] : const [],
    abandonados: const [],
    pendientes: const [],
    generosFavoritos: withActivity
        ? [PerfilGenero(genero: 'Fantasía', total: 2)]
        : const [],
    sagas: withActivity
        ? [
            PerfilSaga(
              id: 'saga-1',
              nombre: 'Saga completa',
              autor: 'Autora',
              leidos: 1,
              totalConocidos: 1,
              totalSaga: 1,
              estado: 'COMPLETADA',
              estadoEditorial: 'FINISHED',
              volumenes: const [
                PerfilSagaVolumen(
                  bookId: 'book-current',
                  titulo: 'Relectura actual',
                  numero: '1',
                  posicion: 1,
                  coverUrl: '',
                  estado: 'LEIDO',
                ),
              ],
            ),
          ]
        : const [],
    historicoMeses: const [],
    favoritos: withActivity
        ? const [LibroFavorito(id: 'fav', title: 'Favorito', coverUrl: '')]
        : const [],
  );
}

PerfilLibroTerminado _finished({
  required String title,
  required String bookId,
  required String completionId,
  required int year,
  bool reread = false,
}) => PerfilLibroTerminado(
  completionId: completionId,
  libraryId: 'library-$completionId',
  bookId: bookId,
  libro: title,
  genero: 'Fantasía',
  fechaInicio: '$year-01-01T10:00:00.000Z',
  fechaFin: '$year-02-01T10:00:00.000Z',
  valoracion: '4',
  resena: '',
  coverUrl: '',
  esRelectura: reread,
);
