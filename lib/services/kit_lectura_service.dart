import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/kit_lectura_seleccion.dart';

class KitLecturaService {
  static const _prefijo = 'kit_lectura_';

  String _clave(String bookId) {
    return '$_prefijo${bookId.trim()}';
  }

  Future<KitLecturaSeleccion> obtener(String bookId) async {
    if (bookId.trim().isEmpty) {
      return const KitLecturaSeleccion();
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clave(bookId));

    if (raw == null || raw.trim().isEmpty) {
      return const KitLecturaSeleccion();
    }

    try {
      final json = jsonDecode(raw);

      if (json is! Map<String, dynamic>) {
        return const KitLecturaSeleccion();
      }

      return KitLecturaSeleccion.fromJson(json);
    } catch (_) {
      return const KitLecturaSeleccion();
    }
  }

  Future<void> guardar(String bookId, KitLecturaSeleccion seleccion) async {
    if (bookId.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_clave(bookId), jsonEncode(seleccion.toJson()));
  }

  Future<void> borrar(String bookId) async {
    if (bookId.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clave(bookId));
  }
}
