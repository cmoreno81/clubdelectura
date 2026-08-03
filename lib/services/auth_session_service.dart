import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import 'token_storage.dart';

class AuthSessionService extends ChangeNotifier {
  AuthSessionService._();

  static final AuthSessionService instance = AuthSessionService._();

  TokenStorage _storage = SecureTokenStorage();
  AuthSession? _session;
  Future<bool>? _refreshInProgress;
  bool _initialized = false;
  bool _sessionExpired = false;

  bool get initialized => _initialized;
  bool get isAuthenticated => _session != null;
  bool get sessionExpired => _sessionExpired;
  AuthUser? get user => _session?.user;
  String? get accessToken => _session?.accessToken;
  String? get refreshToken => _session?.refreshToken;

  Future<bool> refreshOnce(Future<bool> Function() refresh) {
    final current = _refreshInProgress;
    if (current != null) return current;

    final pending = refresh();
    _refreshInProgress = pending;
    return pending.whenComplete(() {
      if (identical(_refreshInProgress, pending)) {
        _refreshInProgress = null;
      }
    });
  }

  Future<void> initialize() async {
    await bootstrap(refreshSession: () async => true);
  }

  Future<void> bootstrap({
    required Future<bool> Function() refreshSession,
  }) async {
    if (_initialized) return;
    try {
      _session = await _storage.read();
      if (_session != null && !await refreshSession()) {
        await _storage.clear();
        _session = null;
      }
    } catch (_) {
      try {
        await _storage.clear();
      } catch (_) {
        // El arranque debe continuar aunque el almacén seguro no esté accesible.
      }
      _session = null;
    }
    _initialized = true;
    _sessionExpired = false;
    notifyListeners();
  }

  Future<void> establish(AuthSession session) async {
    await _storage.write(session);
    _session = session;
    _sessionExpired = false;
    notifyListeners();
  }

  Future<void> replaceTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final current = _session;
    if (current == null) return;
    await _storage.replaceTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    _session = AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: current.user,
    );
  }

  Future<void> clear() async {
    await _storage.clear();
    _session = null;
    _refreshInProgress = null;
    _sessionExpired = false;
    notifyListeners();
  }

  Future<void> expire() async {
    await _storage.clear();
    _session = null;
    _sessionExpired = true;
    notifyListeners();
  }

  @visibleForTesting
  void configureStorage(TokenStorage storage) {
    _storage = storage;
    _session = null;
    _refreshInProgress = null;
    _initialized = false;
    _sessionExpired = false;
  }
}
