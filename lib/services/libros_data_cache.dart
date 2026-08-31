import '../models/libros_data.dart';
import 'auth_session_service.dart';

class LibrosDataCache {
  LibrosDataCache._() {
    AuthSessionService.instance.registerSessionStateCleaner(invalidate);
  }
  static final LibrosDataCache instance = LibrosDataCache._();

  Future<LibrosData>? _inFlight;
  LibrosData? _cached;
  DateTime? _cachedAt;
  String? _cachedForClubId;
  static const _ttl = Duration(seconds: 30);

  bool _isValid(String? clubId) =>
      _cached != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < _ttl &&
      _cachedForClubId == clubId;

  /// Versión pública de _isValid para que otros widgets puedan saber
  /// si el fetch real es necesario (y pre-sincronizar el club).
  bool isValidFor(String? clubId) => _isValid(clubId);

  Future<LibrosData> get(
    Future<LibrosData> Function() fetcher, {
    String? clubId,
  }) {
    if (_isValid(clubId)) return Future.value(_cached);
    // Si el club es distinto al cacheado, cancelar vuelo en curso y limpiar.
    if (_cachedForClubId != clubId) {
      _inFlight = null;
      _cached = null;
      _cachedAt = null;
    }
    _inFlight ??= fetcher()
        .then((data) {
          _cached = data;
          _cachedAt = DateTime.now();
          _cachedForClubId = clubId;
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
    _cachedForClubId = null;
    _inFlight = null;
  }
}
