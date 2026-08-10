import 'package:flutter/foundation.dart';

import '../models/cursor_page.dart';

typedef CursorPageLoader<T> = Future<CursorPage<T>> Function(String? cursor);

class RequestGeneration {
  int _value = 0;

  int begin() => ++_value;
  bool isCurrent(int value) => value == _value;
}

class CursorPaginationController<T> extends ChangeNotifier {
  CursorPaginationController({required this.loadPage, required this.keyOf});

  final CursorPageLoader<T> loadPage;
  final String Function(T item) keyOf;

  List<T> _items = const [];
  List<T> _localTail = const [];
  String? _nextCursor;
  bool _hasMore = true;
  bool _initialLoading = false;
  bool _loadingMore = false;
  Object? _initialError;
  Object? _loadMoreError;
  int _generation = 0;
  bool _disposed = false;

  List<T> get items => List.unmodifiable([..._items, ..._localTail]);
  bool get hasMore => _hasMore;
  bool get initialLoading => _initialLoading;
  bool get loadingMore => _loadingMore;
  Object? get initialError => _initialError;
  Object? get loadMoreError => _loadMoreError;
  bool get showInitialLoader => _initialLoading && items.isEmpty;
  bool get refreshing => _initialLoading && items.isNotEmpty;
  bool get showEmpty =>
      !_initialLoading && items.isEmpty && _initialError == null;
  bool get showInitialError => _initialError != null && items.isEmpty;
  bool get hasContentError => _initialError != null && items.isNotEmpty;

  Future<void> loadFirst() async {
    if (_initialLoading) return;
    final generation = ++_generation;
    _initialLoading = true;
    // Un refresh invalida cualquier página adicional todavía en vuelo.
    _loadingMore = false;
    _initialError = null;
    _loadMoreError = null;
    if (_items.isEmpty) {
      _nextCursor = null;
      _hasMore = true;
    }
    _notify();
    try {
      final page = await loadPage(null);
      if (generation != _generation) return;
      _items = _deduplicated(page.items);
      _removeLocalItemsPresentInPages();
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore && page.nextCursor != null;
    } catch (error) {
      if (generation != _generation) return;
      _initialError = error;
    } finally {
      if (generation == _generation) {
        _initialLoading = false;
        _notify();
      }
    }
  }

  Future<void> loadMore() async {
    if (_initialLoading || _loadingMore || !_hasMore) return;
    final generation = _generation;
    _loadingMore = true;
    _loadMoreError = null;
    _notify();
    try {
      final page = await loadPage(_nextCursor);
      if (generation != _generation) return;
      _items = _deduplicated([..._items, ...page.items]);
      _removeLocalItemsPresentInPages();
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore && page.nextCursor != null;
    } catch (error) {
      if (generation != _generation) return;
      _loadMoreError = error;
    } finally {
      if (generation == _generation) {
        _loadingMore = false;
        _notify();
      }
    }
  }

  void replace(String key, T Function(T current) update) {
    var changed = false;
    _items = List.unmodifiable(
      _items.map((item) {
        if (keyOf(item) != key) return item;
        changed = true;
        return update(item);
      }),
    );
    _localTail = List.unmodifiable(
      _localTail.map((item) {
        if (keyOf(item) != key) return item;
        changed = true;
        return update(item);
      }),
    );
    if (changed) _notify();
  }

  /// Adds a server-confirmed item after all currently loaded pages.
  ///
  /// It remains separate from [_items], so subsequently loaded intermediate
  /// pages are inserted before it. When the server eventually returns the
  /// same ID, the local copy is removed automatically.
  void appendLocal(T item) {
    final key = keyOf(item);
    if (_items.any((value) => keyOf(value) == key)) return;
    _localTail = List.unmodifiable([
      ..._localTail.where((value) => keyOf(value) != key),
      item,
    ]);
    _notify();
  }

  void remove(String key) {
    final pages = _items.where((item) => keyOf(item) != key).toList();
    final local = _localTail.where((item) => keyOf(item) != key).toList();
    if (pages.length == _items.length && local.length == _localTail.length) {
      return;
    }
    _items = List.unmodifiable(pages);
    _localTail = List.unmodifiable(local);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }

  List<T> _deduplicated(Iterable<T> values) {
    final byKey = <String, T>{};
    for (final value in values) {
      byKey.putIfAbsent(keyOf(value), () => value);
    }
    return List.unmodifiable(byKey.values);
  }

  void _removeLocalItemsPresentInPages() {
    if (_localTail.isEmpty) return;
    final pageKeys = _items.map(keyOf).toSet();
    _localTail = List.unmodifiable(
      _localTail.where((item) => !pageKeys.contains(keyOf(item))),
    );
  }
}
