import 'package:shared_preferences/shared_preferences.dart';

/// Mantiene una racha de días seguidos en que el usuario ha abierto la app.
///
/// Claves en SharedPreferences:
///   - `streak_count`     → int, número de días consecutivos
///   - `streak_last_date` → String (yyyy-MM-dd), último día registrado
class ReadingStreakService {
  static const _keyCount = 'streak_count';
  static const _keyLastDate = 'streak_last_date';

  /// Registra la visita de hoy y devuelve la racha actualizada.
  ///
  /// - Misma fecha que la última → sin cambio (idempotente en el mismo día).
  /// - Fecha de ayer            → racha + 1.
  /// - Más de un día de hueco   → reinicia a 1.
  static Future<int> registrarVisita() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _hoy();
    final lastRaw = prefs.getString(_keyLastDate);
    final lastDate = lastRaw != null ? DateTime.tryParse(lastRaw) : null;
    int count = prefs.getInt(_keyCount) ?? 0;

    if (lastDate == null) {
      // Primera vez
      count = 1;
    } else {
      final diff = today.difference(lastDate).inDays;
      if (diff == 0) {
        // Ya registrado hoy, no cambia nada
        return count;
      } else if (diff == 1) {
        count += 1;
      } else {
        // Hueco de más de un día → reinicia
        count = 1;
      }
    }

    await prefs.setInt(_keyCount, count);
    await prefs.setString(_keyLastDate, _formatDate(today));
    return count;
  }

  /// Devuelve la racha actual sin modificar nada.
  static Future<int> obtenerRacha() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRaw = prefs.getString(_keyLastDate);
    if (lastRaw == null) return 0;

    final lastDate = DateTime.tryParse(lastRaw);
    if (lastDate == null) return 0;

    final today = _hoy();
    final diff = today.difference(lastDate).inDays;

    // Si lleva más de 1 día sin abrir la app, la racha se ha roto
    if (diff > 1) return 0;

    return prefs.getInt(_keyCount) ?? 0;
  }

  static DateTime _hoy() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
