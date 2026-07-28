import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session.dart';

abstract class TokenStorage {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> replaceTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'auth_user';
  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    final values = await Future.wait([
      _storage.read(key: _accessTokenKey),
      _storage.read(key: _refreshTokenKey),
      _storage.read(key: _userKey),
    ]);
    if (values.any((value) => value == null || value.isEmpty)) return null;

    try {
      return AuthSession(
        accessToken: values[0]!,
        refreshToken: values[1]!,
        user: AuthUser.fromJson(jsonDecode(values[2]!) as Map<String, dynamic>),
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: session.accessToken),
      _storage.write(key: _refreshTokenKey, value: session.refreshToken),
      _storage.write(key: _userKey, value: jsonEncode(session.user.toJson())),
    ]);
  }

  @override
  Future<void> replaceTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  @override
  Future<void> clear() => Future.wait([
    _storage.delete(key: _accessTokenKey),
    _storage.delete(key: _refreshTokenKey),
    _storage.delete(key: _userKey),
  ]);
}
