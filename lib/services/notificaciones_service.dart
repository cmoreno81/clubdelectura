import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

/// Singleton que centraliza el estado de notificaciones no leídas.
/// Todas las páginas que muestran badges escuchan este servicio en lugar de
/// hacer sus propias peticiones individuales — así el badge del dashboard,
/// de Lecturas y de cualquier otra pestaña siempre están sincronizados.
class NotificacionesService extends ChangeNotifier {
  NotificacionesService._();
  static final NotificacionesService instance = NotificacionesService._();

  int _noLeidas = 0;
  int _noLeidasClub = 0;
  int _noLeidasLecturas = 0;
  int _noLeidasClubvision = 0;

  int get noLeidas => _noLeidas;
  int get noLeidasClub => _noLeidasClub;
  int get noLeidasLecturas => _noLeidasLecturas;
  int get noLeidasClubvision => _noLeidasClubvision;

  /// Carga los contadores desde la API y notifica a los listeners.
  Future<void> cargar() async {
    try {
      final data = await ApiService().getNotificaciones();
      _noLeidas = data.noLeidas;
      _noLeidasClub = data.noLeidasClub;
      _noLeidasLecturas = data.noLeidasLecturas;
      _noLeidasClubvision = data.noLeidasClubvision;
      notifyListeners();
    } catch (_) {
      // Silencioso: mantiene los valores anteriores
    }
  }

  /// Marca todas como leídas en el backend y pone los contadores a 0.
  Future<void> marcarTodas() async {
    try {
      await ApiService().marcarTodasNotificacionesLeidas();
    } catch (_) {}
    _noLeidas = 0;
    _noLeidasClub = 0;
    _noLeidasLecturas = 0;
    _noLeidasClubvision = 0;
    notifyListeners();
  }

  /// Marca una notificación individual como leída y decrementa los contadores.
  /// [tipo] es el campo `tipo` de la notificación — permite decrementar el
  /// contador de categoría correcto además del total.
  Future<void> marcarLeida(String id, {String tipo = ''}) async {
    try {
      await ApiService().marcarNotificacionLeida(id);
    } catch (_) {}
    if (_noLeidas > 0) _noLeidas--;
    // Decrementar también el contador de categoría según el tipo
    switch (tipo) {
      case 'LECTURA_NUEVA':
      case 'COMENTARIO_LECTURA':
        if (_noLeidasLecturas > 0) _noLeidasLecturas--;
      case 'CLUBVISION_ABIERTA':
      case 'CLUBVISION_RESULTADOS':
        if (_noLeidasClubvision > 0) _noLeidasClubvision--;
      default:
        // Tipos de Club (LIBRO_TERMINADO, LIBRO_EMPEZADO, etc.)
        if (tipo.isNotEmpty && _noLeidasClub > 0) _noLeidasClub--;
    }
    notifyListeners();
  }

  /// Resetea los contadores a 0 localmente (tras abrir un sheet que los marcó).
  void resetearLocal() {
    _noLeidas = 0;
    _noLeidasClub = 0;
    _noLeidasLecturas = 0;
    _noLeidasClubvision = 0;
    notifyListeners();
  }
}
