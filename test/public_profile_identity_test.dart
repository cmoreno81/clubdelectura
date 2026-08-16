import 'dart:async';

import 'package:club_lectura_app/models/perfil_usuario.dart';
import 'package:club_lectura_app/pages/perfil_usuario_page.dart';
import 'package:club_lectura_app/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dos perfiles homónimos no mezclan favoritos tardíos', (
    tester,
  ) async {
    final first = Completer<List<LibroFavorito>>();
    final second = Completer<List<LibroFavorito>>();

    Future<List<LibroFavorito>> loader(String id, String _) =>
        id == 'user-a' ? first.future : second.future;

    Widget page(String id) => MaterialApp(
      home: PerfilUsuarioPage(
        key: const ValueKey('profile'),
        usuario: 'Cristina',
        profileUserId: id,
        initialTab: 'FAVORITOS',
        loadCurrentUser: () async => 'Otra cuenta',
        loadProfile: () async => PerfilUsuario.fromJson({
          'userId': id,
          'usuario': 'Cristina',
          'resumen': <String, dynamic>{},
        }),
        loadPublicFavorites: loader,
        bookOfYearPreviewBuilder: (_, _) => const SizedBox.shrink(),
      ),
    );

    await tester.pumpWidget(page('user-a'));
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(page('user-b'));
    await tester.pump();

    second.complete(const [LibroFavorito(id: 'book-b', title: 'Libro B')]);
    await tester.pumpAndSettle();
    expect(find.text('Libro B'), findsOneWidget);

    first.complete(const [LibroFavorito(id: 'book-a', title: 'Libro A')]);
    await tester.pumpAndSettle();
    expect(find.text('Libro B'), findsOneWidget);
    expect(find.text('Libro A'), findsNothing);
  });

  testWidgets('favoritos públicos distinguen vacío de error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PerfilUsuarioPage(
          usuario: 'Cristina',
          profileUserId: 'user-empty',
          initialTab: 'FAVORITOS',
          loadCurrentUser: () async => 'Otra cuenta',
          loadProfile: () async => PerfilUsuario.fromJson(const {
            'userId': 'user-empty',
            'usuario': 'Cristina',
            'resumen': <String, dynamic>{},
          }),
          loadPublicFavorites: (_, _) async => const [],
          bookOfYearPreviewBuilder: (_, _) => const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Todavía no ha marcado favoritos'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: PerfilUsuarioPage(
          usuario: 'Cristina',
          profileUserId: 'user-error',
          initialTab: 'FAVORITOS',
          loadCurrentUser: () async => 'Otra cuenta',
          loadProfile: () async => PerfilUsuario.fromJson(const {
            'userId': 'user-error',
            'usuario': 'Cristina',
            'resumen': <String, dynamic>{},
          }),
          loadPublicFavorites: (_, _) async => throw Exception('fallo'),
          bookOfYearPreviewBuilder: (_, _) => const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Todavía no ha marcado favoritos'), findsNothing);
  });

  testWidgets(
    'cada portada ajena abre su bookId incluso con títulos repetidos',
    (tester) async {
      final opened = <String>[];
      final favorites = List.generate(
        5,
        (index) => LibroFavorito(
          id: 'book-$index',
          title: index < 2 ? 'Título repetido' : 'Libro $index',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PerfilUsuarioPage(
            usuario: 'Bea',
            profileUserId: 'bea-id',
            initialTab: 'FAVORITOS',
            loadCurrentUser: () async => 'Otra cuenta',
            loadProfile: () async => PerfilUsuario.fromJson(const {
              'userId': 'bea-id',
              'usuario': 'Bea',
              'resumen': <String, dynamic>{},
            }),
            loadPublicFavorites: (_, _) async => favorites,
            onOpenFavorite: (favorite) async => opened.add(favorite.bookId),
            bookOfYearPreviewBuilder: (_, _) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (var index = 0; index < 5; index++) {
        await tester.tap(
          find
              .descendant(
                of: find.byKey(ValueKey('favorito_book-$index')),
                matching: find.byType(GestureDetector),
              )
              .first,
        );
        await tester.pump();
      }
      expect(opened, ['book-0', 'book-1', 'book-2', 'book-3', 'book-4']);
      expect(find.byKey(const Key('quitar_favorito')), findsNothing);
      expect(find.byKey(const Key('cambiar_favorito')), findsNothing);
      expect(find.text('Bea'), findsWidgets);
    },
  );

  testWidgets(
    'bloquea una segunda navegación mientras la primera sigue abierta',
    (tester) async {
      final navigation = Completer<void>();
      var opens = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PerfilUsuarioPage(
            usuario: 'Bea',
            profileUserId: 'bea-id',
            initialTab: 'FAVORITOS',
            loadCurrentUser: () async => 'Otra cuenta',
            loadProfile: () async => PerfilUsuario.fromJson(const {
              'userId': 'bea-id',
              'usuario': 'Bea',
              'resumen': <String, dynamic>{},
            }),
            loadPublicFavorites: (_, _) async => const [
              LibroFavorito(id: 'stable-book', title: 'Libro'),
            ],
            onOpenFavorite: (_) {
              opens++;
              return navigation.future;
            },
            bookOfYearPreviewBuilder: (_, _) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final favorite = find
          .descendant(
            of: find.byKey(const ValueKey('favorito_stable-book')),
            matching: find.byType(GestureDetector),
          )
          .first;
      await tester.tap(favorite);
      await tester.tap(favorite);
      await tester.pump();
      expect(opens, 1);
      navigation.complete();
      await tester.pumpAndSettle();
      expect(find.text('Bea'), findsWidgets);
    },
  );

  test('favorito público prioriza bookId y tolera el contrato antiguo', () {
    expect(
      LibroFavorito.fromJson(const {
        'bookId': 'stable',
        'id': 'legacy',
        'title': 'Duplicado',
      }).bookId,
      'stable',
    );
    expect(
      LibroFavorito.fromJson(const {'id': 'legacy', 'title': 'Antiguo'}).bookId,
      'legacy',
    );
  });
}
