// ignore_for_file: avoid_print
import 'dart:async';

import 'package:club_lectura_app/models/book_of_year.dart';
import 'package:club_lectura_app/services/api_exception.dart';
import 'package:club_lectura_app/widgets/profile/book_of_year_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

BookOfYearBoard _board({int selections = 7, bool editable = false}) {
  final book = BookOfYearBook(
    id: 'book-id',
    title: 'Título',
    coverUrl: '',
    authorName: 'Autora',
  );
  return BookOfYearBoard(
    year: DateTime.now().year,
    editable: editable,
    userName: 'Bea',
    avatarUrl: '',
    hasSelections: selections > 0,
    months: List.generate(12, (i) {
      final selected = i < selections ? book : null;
      return BookOfYearMonth(
        month: i + 1,
        locked: false,
        finished: true,
        eligible: selected == null ? [book] : const [],
        selection: selected,
      );
    }),
    duels: const [],
    finalists: const [],
  );
}

ApiException _forbidden() => const ApiException(
  statusCode: 403,
  message: 'No compartís un club visible',
  code: 'FORBIDDEN',
  type: ApiErrorType.forbidden,
);

ApiException _networkError() => const ApiException(
  statusCode: 0,
  message: 'Sin conexión',
  type: ApiErrorType.noConnection,
);

ApiException _serverError() => const ApiException(
  statusCode: 500,
  message: 'Error interno',
  type: ApiErrorType.server,
);

ApiException _userNotFound() => const ApiException(
  statusCode: 400,
  message: 'Usuaria no encontrada',
  code: 'USER_NOT_FOUND',
  type: ApiErrorType.unknown,
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // 1. Perfil de Bea con 7 elecciones
  testWidgets('muestra 7 de 12 meses elegidos cuando Bea tiene 7 selecciones', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        BookOfYearPreview(
          profile: 'Bea',
          profileUserId: 'bea-id',
          editable: false,
          loadBoard: (_, _) async => _board(selections: 7),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7 de 12 meses elegidos'), findsWidgets);
    expect(find.text('Ver cuadro completo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // 2. Perfil ajeno sin Libro del año configurado
  testWidgets('muestra estado "no comenzado" cuando el perfil no tiene selecciones', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        BookOfYearPreview(
          profile: 'Ana',
          profileUserId: 'ana-id',
          editable: false,
          loadBoard: (_, _) async => _board(selections: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Todavía no ha comenzado'), findsOneWidget);
    // No debe aparecer el conteo
    expect(find.textContaining('de 12 meses elegidos'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // 3. Sin permiso (403)
  testWidgets('muestra mensaje de sin permiso ante HTTP 403', (tester) async {
    await tester.pumpWidget(
      _wrap(
        BookOfYearPreview(
          profile: 'Bea',
          profileUserId: 'bea-id',
          editable: false,
          loadBoard: (_, _) async => throw _forbidden(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('comparten club'), findsOneWidget);
    // Sin contador falso
    expect(find.textContaining('de 12 meses'), findsNothing);
    // Sin botón Reintentar (no sirve de nada)
    expect(find.text('Reintentar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // 4. Error de red — con botón Reintentar
  testWidgets('muestra "Sin conexión" y botón Reintentar ante error de red', (
    tester,
  ) async {
    var calls = 0;
    final completer = Completer<BookOfYearBoard>();

    await tester.pumpWidget(
      _wrap(
        BookOfYearPreview(
          profile: 'Bea',
          profileUserId: 'bea-id',
          editable: false,
          loadBoard: (_, _) {
            calls++;
            if (calls == 1) return Future.error(_networkError());
            return completer.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Sin conexión'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    // Sin contador falso
    expect(find.textContaining('de 12 meses'), findsNothing);

    // Simular reconexión: tap en Reintentar
    completer.complete(_board(selections: 7));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('7 de 12 meses elegidos'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  // 5. Error del servidor — con botón Reintentar
  testWidgets('muestra "Error temporal" y Reintentar ante HTTP 500', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        BookOfYearPreview(
          profile: 'Bea',
          profileUserId: 'bea-id',
          editable: false,
          loadBoard: (_, _) => Future.error(_serverError()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Error temporal'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('de 12 meses'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // 6. Respuesta sin campos opcionales (winner, finalists vacíos)
  testWidgets('no falla con respuesta válida parcial sin ganador ni finalistas', (
    tester,
  ) async {
    final board = BookOfYearBoard(
      year: DateTime.now().year,
      editable: false,
      userName: 'Bea',
      avatarUrl: '',
      hasSelections: true,
      months: List.generate(
        12,
        (i) => BookOfYearMonth(
          month: i + 1,
          locked: false,
          finished: true,
          eligible: const [],
          selection: i < 3
              ? BookOfYearBook(
                  id: 'b$i',
                  title: 'Libro $i',
                  coverUrl: '',
                  authorName: '',
                )
              : null,
        ),
      ),
      duels: const [],
      finalists: const [],
      // winner: null — campo opcional ausente
    );

    await tester.pumpWidget(
      _wrap(
        BookOfYearPreview(
          profile: 'Bea',
          profileUserId: 'bea-id',
          editable: false,
          loadBoard: (_, _) async => board,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 de 12 meses elegidos'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  // 7. Falta deliberada del identificador — error controlado, no excepción
  testWidgets('muestra error controlado cuando profile está vacío', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        BookOfYearPreview(
          profile: '', // Deliberadamente vacío
          profileUserId: null,
          editable: false,
          // loadBoard null → usa lógica interna → detecta profile vacío
          // → devuelve Future.error(StateError) → no lanza síncronamente
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo identificar'), findsOneWidget);
    // Sin contador falso
    expect(find.textContaining('de 12 meses'), findsNothing);
    // Sin botón Reintentar (no ayuda)
    expect(find.text('Reintentar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // 8. Cambio rápido entre Bea y otro perfil — no hay contaminación de datos
  testWidgets('cambio rápido de perfil usa los datos del último solicitado', (
    tester,
  ) async {
    final beaCompleter = Completer<BookOfYearBoard>();
    final anaCompleter = Completer<BookOfYearBoard>();

    Widget preview(String profile, String userId) => _wrap(
      BookOfYearPreview(
        key: ValueKey(userId),
        profile: profile,
        profileUserId: userId,
        editable: false,
        loadBoard: (_, _) =>
            userId == 'bea-id' ? beaCompleter.future : anaCompleter.future,
      ),
    );

    await tester.pumpWidget(preview('Bea', 'bea-id'));
    await tester.pump(); // Carga iniciada para Bea

    // Cambio rápido a Ana antes de que Bea termine
    await tester.pumpWidget(preview('Ana', 'ana-id'));
    await tester.pump();

    // Ana responde primero
    anaCompleter.complete(_board(selections: 3));
    await tester.pumpAndSettle();

    expect(find.text('3 de 12 meses elegidos'), findsWidgets);

    // Bea responde tarde — no debe contaminar los datos mostrados
    beaCompleter.complete(_board(selections: 7));
    await tester.pumpAndSettle();

    // Seguimos viendo los 3 meses de Ana
    expect(find.text('3 de 12 meses elegidos'), findsWidgets);
    expect(find.text('7 de 12 meses elegidos'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // 9. Nunca aparecen contador falso y estado de error simultáneamente
  testWidgets(
    'nunca muestra "0 de 12 meses elegidos" junto a un mensaje de error',
    (tester) async {
      for (final error in [_forbidden(), _networkError(), _serverError(), _userNotFound()]) {
        await tester.pumpWidget(
          _wrap(
            BookOfYearPreview(
              profile: 'Bea',
              profileUserId: 'bea-id',
              editable: false,
              loadBoard: (_, _) => Future.error(error),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Nunca debe aparecer "0 de 12 meses"
        expect(
          find.text('0 de 12 meses elegidos'),
          findsNothing,
          reason: 'Con error ${error.code ?? error.type} apareció "0 de 12"',
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  // 10. Reintentar solo recarga Libro del año, no todo el perfil
  testWidgets('Reintentar solo lanza una nueva carga de Libro del año', (
    tester,
  ) async {
    var boardLoads = 0;
    final completer = Completer<BookOfYearBoard>();

    await tester.pumpWidget(
      _wrap(
        BookOfYearPreview(
          profile: 'Bea',
          profileUserId: 'bea-id',
          editable: false,
          loadBoard: (_, _) {
            boardLoads++;
            if (boardLoads == 1) return Future.error(_networkError());
            return completer.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reintentar'), findsOneWidget);
    expect(boardLoads, 1);

    completer.complete(_board(selections: 7));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    // Solo se han disparado 2 cargas de board (inicial + reintentar)
    expect(boardLoads, 2);
    expect(find.text('7 de 12 meses elegidos'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  // 11. Perfil propio usa la carga editable
  testWidgets('perfil propio usa loadBoard con editable=true', (tester) async {
    bool? receivedEditable;

    await tester.pumpWidget(
      _wrap(
        BookOfYearPreview(
          profile: 'Yo',
          profileUserId: 'my-id',
          editable: true,
          loadBoard: (_, editable) async {
            receivedEditable = editable;
            return _board(selections: 2, editable: true);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(receivedEditable, isTrue);
    expect(find.text('Mi libro del año'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // 12. Perfil con nombre pero sin ID: no lanza excepción no controlada
  testWidgets('solo nombre sin profileUserId hace la carga sin crashear', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        BookOfYearPreview(
          profile: 'Bea',
          profileUserId: null, // Sin ID estable — OK si llega nombre
          editable: false,
          loadBoard: (_, _) async => _board(selections: 7),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7 de 12 meses elegidos'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
