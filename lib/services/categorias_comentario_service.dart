import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subrayador_categoria.dart';
import 'api_service.dart';
import 'auth_session_service.dart';

/// Nombres y emojis que cada lectora da a las 5 categorías de comentario
/// (Momento fav., Teoría, Cita, Personaje, Impacto). Se guardan en la cuenta
/// —para no perderlos al cambiar de móvil— y en el móvil como copia rápida.
///
/// «Cita del libro» (la tercera) se puede renombrar, pero sigue siendo una
/// cita: el formato en cursiva viene de [SubrayadorCategoria.esCita], que no
/// se edita.
class CategoriasComentarioService {
  CategoriasComentarioService._();

  static const nombreMax = 24;
  static const emojiMax = 8;

  static final ValueNotifier<List<SubrayadorCategoria>> _categorias =
      ValueNotifier(kSubrayadorCategorias);
  static String? _usuarioCargado;

  /// Categorías en uso (las personalizadas o, si no hay, las de siempre).
  static ValueListenable<List<SubrayadorCategoria>> get categorias {
    _cargarSiHaceFalta();
    return _categorias;
  }

  /// `true` si alguna categoría difiere de la de siempre.
  static bool get estaPersonalizado {
    for (var i = 0; i < kSubrayadorCategorias.length; i++) {
      final actual = _categorias.value[i];
      final base = kSubrayadorCategorias[i];
      if (actual.nombre != base.nombre || actual.emoji != base.emoji) {
        return true;
      }
    }
    return false;
  }

  static String get _usuario =>
      AuthSessionService.instance.user?.id.trim() ?? 'anonymous';

  static String get _clave => 'categorias_comentario_$_usuario';

  static List<SubrayadorCategoria>? _desdeJson(Object? raw) {
    if (raw is! List || raw.length != kSubrayadorCategorias.length) return null;
    final resultado = <SubrayadorCategoria>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) return null;
      final nombre = _limpiar(item['nombre'], nombreMax);
      if (nombre.isEmpty) return null;
      resultado.add(
        SubrayadorCategoria(
          emoji: _limpiar(item['emoji'], emojiMax),
          nombre: nombre,
          // Qué categoría es una cita no se puede cambiar.
          esCita: kSubrayadorCategorias[i].esCita,
        ),
      );
    }
    return resultado;
  }

  static String _limpiar(Object? valor, int max) {
    final texto = (valor?.toString() ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final runas = texto.runes.toList();
    return runas.length <= max ? texto : String.fromCharCodes(runas.take(max));
  }

  static List<Map<String, String>> _aJson(List<SubrayadorCategoria> lista) => [
    for (final c in lista) {'emoji': c.emoji, 'nombre': c.nombre},
  ];

  static Future<void> _cargarSiHaceFalta() async {
    final usuario = _usuario;
    if (_usuarioCargado == usuario) return;
    _usuarioCargado = usuario;
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getString(_clave);
      if (local != null) {
        final categorias = _desdeJson(jsonDecode(local));
        if (categorias != null) _categorias.value = categorias;
      } else {
        _categorias.value = kSubrayadorCategorias;
      }
      if (usuario == 'anonymous') return;
      final remotas = await ApiService().obtenerCategoriasComentario();
      // Sin conexión (null) se queda lo que hay en el móvil.
      if (remotas == null) return;
      final categorias = _desdeJson(remotas);
      if (categorias != null) {
        _categorias.value = categorias;
        await prefs.setString(_clave, jsonEncode(_aJson(categorias)));
      }
    } catch (_) {}
  }

  /// Guarda las categorías editadas. Devuelve `false` si no se ha podido
  /// guardar en la cuenta (en el móvil se guardan igualmente).
  static Future<bool> guardar(List<SubrayadorCategoria> nuevas) async {
    final limpias = _desdeJson(_aJson(nuevas));
    if (limpias == null) return false;
    _usuarioCargado = _usuario;
    _categorias.value = limpias;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_clave, jsonEncode(_aJson(limpias)));
    } catch (_) {}
    if (_usuario == 'anonymous') return true;
    return ApiService().guardarCategoriasComentario(_aJson(limpias));
  }

  /// Vuelve a los nombres de siempre.
  static Future<bool> restablecer() async {
    _usuarioCargado = _usuario;
    _categorias.value = kSubrayadorCategorias;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clave);
    } catch (_) {}
    if (_usuario == 'anonymous') return true;
    return ApiService().guardarCategoriasComentario(null);
  }

  /// Solo para tests.
  @visibleForTesting
  static void reiniciar() {
    _usuarioCargado = null;
    _categorias.value = kSubrayadorCategorias;
  }
}
