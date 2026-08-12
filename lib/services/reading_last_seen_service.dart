import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el momento en que el usuario abrió cada lectura por última vez.
///
/// Clave: `reading_seen_<título normalizado>`
/// Valor: ISO-8601 del instante de apertura.
///
/// Permite mostrar un indicador de "actividad nueva" en la tarjeta de
/// lectura comparando ese timestamp con [LecturaActiva.ultimaActividad].
class ReadingLastSeenService {
  static const _prefix = 'reading_seen_';

  static String _key(String titulo) =>
      '$_prefix${titulo.trim().toLowerCase().replaceAll(' ', '_')}';

  /// Registra que el usuario acaba de abrir [titulo].
  static Future<void> marcarVista(String titulo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(titulo), DateTime.now().toIso8601String());
  }

  /// Devuelve el instante en que el usuario abrió [titulo] por última vez,
  /// o `null` si nunca la ha abierto.
  static Future<DateTime?> ultimaVista(String titulo) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(titulo));
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Carga en bloque los timestamps de una lista de títulos.
  /// Más eficiente que llamar a [ultimaVista] una vez por lectura.
  static Future<Map<String, DateTime>> ultimasVistas(
    Iterable<String> titulos,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, DateTime>{};
    for (final titulo in titulos) {
      final raw = prefs.getString(_key(titulo));
      if (raw != null) {
        final dt = DateTime.tryParse(raw);
        if (dt != null) result[titulo] = dt;
      }
    }
    return result;
  }
}
