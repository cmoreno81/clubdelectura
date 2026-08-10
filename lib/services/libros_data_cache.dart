import '../models/libros_data.dart';

class LibrosDataCache {
  LibrosDataCache._();
  static final LibrosDataCache instance = LibrosDataCache._();

  Future<LibrosData>? _inFlight;
  LibrosData? _cached;
  DateTime? _cachedAt;
  static const _ttl = Duration(seconds: 30);

  bool get _isValid =>
      _cached != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < _ttl;

  Future<LibrosData> get(Future<LibrosData> Function() fetcher) {
    if (_isValid) return Future.value(_cached);
    _inFlight ??= fetcher()
        .then((data) {
          _cached = data;
          _cachedAt = DateTime.now();
          _inFlight = null;
          return data;
        })
        .catchError((err) {
          _inFlight = null;
          throw err;
        });
    return _inFlight!;
  }

  void invalidate() {
    _cached = null;
    _cachedAt = null;
    _inFlight = null;
  }
}
