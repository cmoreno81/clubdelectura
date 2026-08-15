import 'package:flutter/foundation.dart';

import '../models/notificacion.dart';
import 'api_service.dart';
import 'auth_session_service.dart';

/// Singleton que centraliza el estado de notificaciones no leídas.
/// Todas las páginas que muestran badges escuchan este servicio en lugar de
/// hacer sus propias peticiones individuales — así el badge del dashboard,
/// de Lecturas y de cualquier otra pestaña siempre están sincronizados.
class NotificacionesService extends ChangeNotifier {
  NotificacionesService._({ApiService? api}) : _api = api ?? ApiService() {
    AuthSessionService.instance.registerSessionStateCleaner(limpiar);
  }
  @visibleForTesting
  NotificacionesService.testing(ApiService api) : _api = api;
  static final NotificacionesService instance = NotificacionesService._();
  final ApiService _api;

  int _noLeidas = 0;
  int _noLeidasClub = 0;
  int _noLeidasLecturas = 0;
  int _noLeidasClubvision = 0;
  int _loadGeneration = 0;
  final Set<String> _readLocally = {};
  final Set<String> _mutatingIds = {};

  int get noLeidas => _noLeidas;
  int get noLeidasClub => _noLeidasClub;
  int get noLeidasLecturas => _noLeidasLecturas;
  int get noLeidasClubvision => _noLeidasClubvision;

  /// Carga los contadores desde la API y notifica a los listeners.
  Future<void> cargar() async {
    final generation = ++_loadGeneration;
    try {
      final data = await _api.getNotificaciones();
      if (generation != _loadGeneration) return;
      _noLeidas = data.noLeidas;
      _noLeidasClub = data.noLeidasClub;
      _noLeidasLecturas = data.noLeidasLecturas;
      _noLeidasClubvision = data.noLeidasClubvision;
      _readLocally
        ..clear()
        ..addAll(data.notificaciones.where((n) => n.leida).map((n) => n.id));
      notifyListeners();
    } catch (_) {
      // Silencioso: mantiene los valores anteriores
    }
  }

  /// Marca todas como leídas en el backend y pone los contadores a 0.
  Future<void> marcarTodas() async {
    _loadGeneration++;
    await _api.marcarTodasNotificacionesLeidas();
    _ponerACero();
    await cargar();
  }

  Future<void> eliminarTodas() async {
    _loadGeneration++;
    await _api.eliminarTodasNotificaciones();
    _readLocally.clear();
    _ponerACero();
    await cargar();
  }

  void _ponerACero() {
    _noLeidas = 0;
    _noLeidasClub = 0;
    _noLeidasLecturas = 0;
    _noLeidasClubvision = 0;
    notifyListeners();
  }

  /// Marca una notificación individual como leída y decrementa los contadores.
  /// [tipo] es el campo `tipo` de la notificación — permite decrementar el
  /// contador de categoría correcto además del total.
  Future<void> marcarLeida(
    String id, {
    required String tipo,
    bool yaLeida = false,
  }) async {
    if (yaLeida || _readLocally.contains(id) || !_mutatingIds.add(id)) return;
    _loadGeneration++;
    try {
      await _api.marcarNotificacionLeida(id);
      _readLocally.add(id);
      _decrementar(tipo);
      notifyListeners();
    } finally {
      _mutatingIds.remove(id);
    }
  }

  Future<void> eliminar(Notificacion notificacion) async {
    _loadGeneration++;
    if (!_mutatingIds.add(notificacion.id)) return;
    try {
      await _api.eliminarNotificacion(notificacion.id);
      if (!notificacion.leida && !_readLocally.contains(notificacion.id)) {
        _readLocally.add(notificacion.id);
        _decrementar(notificacion.tipo);
        notifyListeners();
      }
    } finally {
      _mutatingIds.remove(notificacion.id);
    }
  }

  void _decrementar(String tipo) {
    _noLeidas = (_noLeidas - 1).clamp(0, 1 << 30);
    switch (notificationBadgeCategory(tipo)) {
      case NotificationBadgeCategory.club:
        _noLeidasClub = (_noLeidasClub - 1).clamp(0, 1 << 30);
      case NotificationBadgeCategory.lecturas:
        _noLeidasLecturas = (_noLeidasLecturas - 1).clamp(0, 1 << 30);
      case NotificationBadgeCategory.clubvision:
        _noLeidasClubvision = (_noLeidasClubvision - 1).clamp(0, 1 << 30);
    }
  }

  void limpiar() {
    _loadGeneration++;
    _readLocally.clear();
    _mutatingIds.clear();
    _ponerACero();
  }
}
