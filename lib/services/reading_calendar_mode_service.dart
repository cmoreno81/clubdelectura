import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cómo se dibujan las portadas en el calendario de lectura:
/// - `false` (por defecto): la portada aparece todos los días que duró la
///   lectura, desde que se empezó hasta que se terminó.
/// - `true`: la portada aparece solo el día en que se terminó el libro.
///
/// Es una preferencia de la lectora que comparten todos los calendarios de la
/// app (inicio, meses lectores y tarjeta para compartir).
class ReadingCalendarModeService {
  const ReadingCalendarModeService._();

  static const _prefsKey = 'reading_calendar_solo_dia_fin';
  static final ValueNotifier<bool> _soloDiaDeFin = ValueNotifier(false);
  static bool _cargado = false;

  /// Valor actual. La primera vez que se pide se lee lo guardado en el móvil.
  static ValueListenable<bool> get soloDiaDeFin {
    _cargar();
    return _soloDiaDeFin;
  }

  static Future<void> _cargar() async {
    if (_cargado) return;
    _cargado = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getBool(_prefsKey);
      if (guardado != null) _soloDiaDeFin.value = guardado;
    } catch (_) {
      // Sin preferencias disponibles se queda el modo por defecto.
    }
  }

  static Future<void> cambiar(bool soloDiaDeFin) async {
    _cargado = true;
    _soloDiaDeFin.value = soloDiaDeFin;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, soloDiaDeFin);
    } catch (_) {}
  }

  /// Solo para tests: vuelve al estado inicial.
  @visibleForTesting
  static void reiniciar() {
    _cargado = false;
    _soloDiaDeFin.value = false;
  }
}
