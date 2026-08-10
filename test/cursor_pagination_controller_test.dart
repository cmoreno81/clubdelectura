import 'dart:async';

import 'package:club_lectura_app/models/cursor_page.dart';
import 'package:club_lectura_app/services/cursor_pagination_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  test('no muestra vacío mientras la primera página está cargando', () async {
    final pending = Completer<CursorPage<_Item>>();
    final controller = CursorPaginationController<_Item>(
      loadPage: (_) => pending.future,
      keyOf: (item) => item.id,
    );

    final request = controller.loadFirst();
    expect(controller.showInitialLoader, isTrue);
    expect(controller.showEmpty, isFalse);

    pending.complete(
      const CursorPage(items: [], nextCursor: null, hasMore: false),
    );
    await request;
    expect(controller.showInitialLoader, isFalse);
    expect(controller.showEmpty, isTrue);
  });

  test('la primera página con comentarios muestra la lista final', () async {
    final pending = Completer<CursorPage<_Item>>();
    final controller = CursorPaginationController<_Item>(
      loadPage: (_) => pending.future,
      keyOf: (item) => item.id,
    );
    final request = controller.loadFirst();
    pending.complete(
      const CursorPage(items: [_Item('a')], nextCursor: null, hasMore: false),
    );
    await request;

    expect(controller.items.single.id, 'a');
    expect(controller.showEmpty, isFalse);
  });

  test('primera página sustituye la colección', () async {
    final controller = CursorPaginationController<_Item>(
      loadPage: (_) async => const CursorPage(
        items: [_Item('a'), _Item('b')],
        nextCursor: 'next',
        hasMore: true,
      ),
      keyOf: (item) => item.id,
    );

    await controller.loadFirst();

    expect(controller.items.map((item) => item.id), ['a', 'b']);
    expect(controller.hasMore, isTrue);
    expect(controller.initialError, isNull);
  });

  test(
    'página siguiente añade, elimina duplicados y conserva los visibles',
    () async {
      var calls = 0;
      final controller = CursorPaginationController<_Item>(
        loadPage: (cursor) async {
          calls++;
          return calls == 1
              ? const CursorPage(
                  items: [_Item('a'), _Item('b')],
                  nextCursor: 'next',
                  hasMore: true,
                )
              : const CursorPage(
                  items: [_Item('b'), _Item('c')],
                  nextCursor: null,
                  hasMore: false,
                );
        },
        keyOf: (item) => item.id,
      );
      await controller.loadFirst();
      final originalList = controller.items;

      await controller.loadMore();

      expect(controller.items.map((item) => item.id), ['a', 'b', 'c']);
      expect(controller.items.take(2), originalList);
      expect(controller.hasMore, isFalse);
      await controller.loadMore();
      expect(calls, 2);
    },
  );

  test('error al cargar más mantiene elementos y permite reintentar', () async {
    var calls = 0;
    final controller = CursorPaginationController<_Item>(
      loadPage: (_) async {
        calls++;
        if (calls == 1) {
          return const CursorPage(
            items: [_Item('a')],
            nextCursor: 'next',
            hasMore: true,
          );
        }
        if (calls == 2) throw StateError('fallo temporal');
        return const CursorPage(
          items: [_Item('b')],
          nextCursor: null,
          hasMore: false,
        );
      },
      keyOf: (item) => item.id,
    );
    await controller.loadFirst();

    await controller.loadMore();
    expect(controller.items.map((item) => item.id), ['a']);
    expect(controller.loadMoreError, isNotNull);

    await controller.loadMore();
    expect(controller.items.map((item) => item.id), ['a', 'b']);
    expect(controller.loadMoreError, isNull);
  });

  test('un refresh conserva elementos y su error no los elimina', () async {
    final refresh = Completer<CursorPage<_Item>>();
    var calls = 0;
    final controller = CursorPaginationController<_Item>(
      loadPage: (_) {
        calls++;
        if (calls == 1) {
          return Future.value(
            const CursorPage(
              items: [_Item('a')],
              nextCursor: null,
              hasMore: false,
            ),
          );
        }
        return refresh.future;
      },
      keyOf: (item) => item.id,
    );
    await controller.loadFirst();

    final request = controller.loadFirst();
    expect(controller.refreshing, isTrue);
    expect(controller.items.single.id, 'a');
    expect(controller.showInitialLoader, isFalse);
    refresh.completeError(StateError('fallo'));
    await request;

    expect(controller.items.single.id, 'a');
    expect(controller.hasContentError, isTrue);
  });

  test('dos loadFirst simultáneos producen una única petición', () async {
    final pending = Completer<CursorPage<_Item>>();
    var calls = 0;
    final controller = CursorPaginationController<_Item>(
      loadPage: (_) {
        calls++;
        return pending.future;
      },
      keyOf: (item) => item.id,
    );

    final first = controller.loadFirst();
    final duplicate = controller.loadFirst();
    expect(calls, 1);
    pending.complete(
      const CursorPage(items: [], nextCursor: null, hasMore: false),
    );
    await Future.wait([first, duplicate]);
    expect(calls, 1);
  });

  test('dos loadMore simultáneos producen una única petición', () async {
    final nextPage = Completer<CursorPage<_Item>>();
    var calls = 0;
    final controller = CursorPaginationController<_Item>(
      loadPage: (cursor) {
        calls++;
        if (cursor == null) {
          return Future.value(
            const CursorPage(
              items: [_Item('a')],
              nextCursor: 'next',
              hasMore: true,
            ),
          );
        }
        return nextPage.future;
      },
      keyOf: (item) => item.id,
    );
    await controller.loadFirst();

    final first = controller.loadMore();
    final duplicate = controller.loadMore();
    expect(calls, 2);
    expect(controller.items.map((item) => item.id), ['a']);
    nextPage.complete(
      const CursorPage(items: [_Item('b')], nextCursor: null, hasMore: false),
    );
    await Future.wait([first, duplicate]);

    expect(calls, 2);
    expect(controller.items.map((item) => item.id), ['a', 'b']);
  });

  test('refresh durante loadMore conserva datos y limpia su loader', () async {
    final stalePage = Completer<CursorPage<_Item>>();
    var firstPageCalls = 0;
    final controller = CursorPaginationController<_Item>(
      loadPage: (cursor) {
        if (cursor != null) return stalePage.future;
        firstPageCalls++;
        return Future.value(
          CursorPage(
            items: [_Item(firstPageCalls == 1 ? 'a' : 'fresh')],
            nextCursor: firstPageCalls == 1 ? 'next' : null,
            hasMore: firstPageCalls == 1,
          ),
        );
      },
      keyOf: (item) => item.id,
    );
    await controller.loadFirst();
    final loadMore = controller.loadMore();
    expect(controller.loadingMore, isTrue);

    await controller.loadFirst();
    expect(controller.loadingMore, isFalse);
    expect(controller.items.map((item) => item.id), ['fresh']);

    stalePage.complete(
      const CursorPage(
        items: [_Item('stale')],
        nextCursor: null,
        hasMore: false,
      ),
    );
    await loadMore;
    expect(controller.items.map((item) => item.id), ['fresh']);
  });

  test('un refresh ascendente sitúa el comentario nuevo al final', () async {
    var calls = 0;
    final controller = CursorPaginationController<_Item>(
      loadPage: (_) async {
        calls++;
        return calls == 1
            ? const CursorPage(
                items: [_Item('old')],
                nextCursor: null,
                hasMore: false,
              )
            : const CursorPage(
                items: [_Item('old'), _Item('new')],
                nextCursor: null,
                hasMore: false,
              );
      },
      keyOf: (item) => item.id,
    );

    await controller.loadFirst();
    await controller.loadFirst();
    expect(controller.items.map((item) => item.id), ['old', 'new']);
  });

  test('comentario local queda tras una conversación de una página', () async {
    final controller = CursorPaginationController<_Item>(
      loadPage: (_) async => const CursorPage(
        items: [_Item('old')],
        nextCursor: null,
        hasMore: false,
      ),
      keyOf: (item) => item.id,
    );
    await controller.loadFirst();

    controller.appendLocal(const _Item('new'));

    expect(controller.items.map((item) => item.id), ['old', 'new']);
  });

  test('páginas intermedias se insertan antes del comentario local', () async {
    final controller = CursorPaginationController<_Item>(
      loadPage: (cursor) async => cursor == null
          ? const CursorPage(
              items: [_Item('old')],
              nextCursor: 'middle',
              hasMore: true,
            )
          : const CursorPage(
              items: [_Item('middle')],
              nextCursor: 'last',
              hasMore: true,
            ),
      keyOf: (item) => item.id,
    );
    await controller.loadFirst();
    controller.appendLocal(const _Item('new'));

    await controller.loadMore();

    expect(controller.items.map((item) => item.id), ['old', 'middle', 'new']);
  });

  test(
    'deduplica el comentario local cuando llega desde el servidor',
    () async {
      var page = 0;
      final controller = CursorPaginationController<_Item>(
        loadPage: (_) async {
          page++;
          return page == 1
              ? const CursorPage(
                  items: [_Item('old')],
                  nextCursor: 'last',
                  hasMore: true,
                )
              : const CursorPage(
                  items: [_Item('new')],
                  nextCursor: null,
                  hasMore: false,
                );
        },
        keyOf: (item) => item.id,
      );
      await controller.loadFirst();
      controller.appendLocal(const _Item('new'));

      await controller.loadMore();

      expect(controller.items.map((item) => item.id), ['old', 'new']);
    },
  );

  testWidgets('insertar comentario local conserva el scroll actual', (
    tester,
  ) async {
    final controller = CursorPaginationController<_Item>(
      loadPage: (_) async => CursorPage(
        items: List.generate(40, (index) => _Item('$index')),
        nextCursor: null,
        hasMore: false,
      ),
      keyOf: (item) => item.id,
    );
    final scrollController = ScrollController();
    await controller.loadFirst();
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: controller,
          builder: (_, _) => ListView.builder(
            controller: scrollController,
            itemExtent: 50,
            itemCount: controller.items.length,
            itemBuilder: (_, index) => Text(controller.items[index].id),
          ),
        ),
      ),
    );
    scrollController.jumpTo(500);
    await tester.pump();

    controller.appendLocal(const _Item('new'));
    await tester.pump();

    expect(scrollController.offset, 500);
    scrollController.dispose();
    controller.dispose();
  });

  test('el guard ignora respuestas de búsquedas anteriores', () {
    final generation = RequestGeneration();
    final oldRequest = generation.begin();
    final currentRequest = generation.begin();

    expect(generation.isCurrent(oldRequest), isFalse);
    expect(generation.isCurrent(currentRequest), isTrue);
  });

  testWidgets('añadir una página no altera la posición del scroll', (
    tester,
  ) async {
    var calls = 0;
    final controller = CursorPaginationController<_Item>(
      loadPage: (_) async {
        calls++;
        final start = calls == 1 ? 0 : 40;
        return CursorPage(
          items: List.generate(40, (index) => _Item('${start + index}')),
          nextCursor: calls == 1 ? 'next' : null,
          hasMore: calls == 1,
        );
      },
      keyOf: (item) => item.id,
    );
    final scrollController = ScrollController();
    await controller.loadFirst();
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: controller,
          builder: (_, _) => ListView.builder(
            controller: scrollController,
            itemExtent: 50,
            itemCount: controller.items.length,
            itemBuilder: (_, index) => Text(controller.items[index].id),
          ),
        ),
      ),
    );
    scrollController.jumpTo(500);
    await tester.pump();

    await controller.loadMore();
    await tester.pump();

    expect(scrollController.offset, 500);
    scrollController.dispose();
    controller.dispose();
  });
}

class _Item {
  const _Item(this.id);
  final String id;

  @override
  bool operator ==(Object other) => other is _Item && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
