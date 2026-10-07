import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/kit_lectura_seleccion.dart';
import 'api_service.dart';
import 'auth_session_service.dart';

/// Dónde vive el kit en el servidor. Se puede sustituir en las pruebas.
abstract class KitLecturaRemoto {
  Future<({bool ok, Map<String, dynamic>? kit, DateTime? actualizado})> leer(
    String bookId,
  );

  /// Fecha con la que el servidor guardó el kit, o null si falló.
  Future<DateTime?> escribir(String bookId, Map<String, dynamic> kit);
}

class _KitRemotoApi implements KitLecturaRemoto {
  @override
  Future<({bool ok, Map<String, dynamic>? kit, DateTime? actualizado})> leer(
    String bookId,
  ) => ApiService().getKitLectura(bookId);

  @override
  Future<DateTime?> escribir(String bookId, Map<String, dynamic> kit) =>
      ApiService().guardarKitLectura(bookId, kit);
}

/// Kit de lectura (paleta, subrayadores, atmósfera…). Se guarda en el móvil y
/// en la cuenta: el móvil sirve de copia rápida y sin conexión, y la cuenta
/// evita perderlo al reinstalar la app o cambiar de móvil.
class KitLecturaService {
  KitLecturaService({KitLecturaRemoto? remoto})
    : _remoto = remoto ?? _KitRemotoApi();

  static const _prefijo = 'kit_lectura_';
  static const _sufijoFecha = '_ts';
  static const _sufijoSync = '_sync';

  final KitLecturaRemoto _remoto;

  String get _usuario => AuthSessionService.instance.user?.id.trim() ?? 'anonymous';

  String _clave(String bookId) => '$_prefijo${_usuario}_${bookId.trim()}';

  Future<KitLecturaSeleccion> obtener(String bookId) async {
    if (bookId.trim().isEmpty) {
      return const KitLecturaSeleccion();
    }

    final prefs = await SharedPreferences.getInstance();
    final clave = _clave(bookId);
    final local = _leerLocal(prefs, clave);
    final fechaLocal = prefs.getInt('$clave$_sufijoFecha');
    final sincronizado = prefs.getInt('$clave$_sufijoSync') ?? 0;

    if (_usuario == 'anonymous') {
      return local == null
          ? const KitLecturaSeleccion()
          : KitLecturaSeleccion.fromJson(local);
    }

    final remoto = await _remoto.leer(bookId.trim());
    // Sin conexión o con error se sigue con lo que hay en el móvil.
    if (!remoto.ok) {
      return local == null
          ? const KitLecturaSeleccion()
          : KitLecturaSeleccion.fromJson(local);
    }

    final kitRemoto = remoto.kit;
    final fechaRemota = remoto.actualizado?.millisecondsSinceEpoch ?? 0;

    if (kitRemoto == null) {
      // La cuenta aún no lo tiene: lo que haya en el móvil se sube.
      if (local == null) return const KitLecturaSeleccion();
      await _subir(prefs, clave, bookId, local);
      return KitLecturaSeleccion.fromJson(local);
    }

    // Un cambio hecho en este móvil y aún sin subir (más nuevo que la cuenta)
    // gana; en cualquier otro caso manda la cuenta.
    final cambioSinSubir =
        local != null &&
        fechaLocal != null &&
        fechaLocal > sincronizado &&
        fechaLocal > fechaRemota;
    if (cambioSinSubir) {
      await _subir(prefs, clave, bookId, local);
      return KitLecturaSeleccion.fromJson(local);
    }

    await prefs.setString(clave, jsonEncode(kitRemoto));
    await prefs.setInt('$clave$_sufijoFecha', fechaRemota);
    await prefs.setInt('$clave$_sufijoSync', fechaRemota);
    return KitLecturaSeleccion.fromJson(kitRemoto);
  }

  Future<void> guardar(String bookId, KitLecturaSeleccion seleccion) async {
    if (bookId.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final clave = _clave(bookId);
    final json = seleccion.toJson();

    await prefs.setString(clave, jsonEncode(json));
    await prefs.setInt('$clave$_sufijoFecha', DateTime.now().millisecondsSinceEpoch);

    if (_usuario == 'anonymous') return;
    await _subir(prefs, clave, bookId, json);
  }

  Future<void> borrar(String bookId) async {
    if (bookId.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final clave = _clave(bookId);
    await prefs.remove(clave);
    await prefs.remove('$clave$_sufijoFecha');
    await prefs.remove('$clave$_sufijoSync');
  }

  /// Sube a la cuenta los kits que están solo en este móvil (los de antes de
  /// que existiera la copia en la cuenta y los guardados sin conexión). Si la
  /// cuenta ya tiene uno más reciente no lo pisa.
  Future<void> subirPendientes() async {
    if (_usuario == 'anonymous') return;
    final prefs = await SharedPreferences.getInstance();
    final prefijo = '$_prefijo${_usuario}_';
    final pendientes = <String>[];
    for (final clave in prefs.getKeys()) {
      if (!clave.startsWith(prefijo)) continue;
      if (clave.endsWith(_sufijoFecha) || clave.endsWith(_sufijoSync)) continue;
      final fecha = prefs.getInt('$clave$_sufijoFecha') ?? 0;
      final sincronizado = prefs.getInt('$clave$_sufijoSync') ?? 0;
      // Sin fecha de sincronización, o modificado después de la última.
      if (sincronizado == 0 || fecha > sincronizado) {
        pendientes.add(clave.substring(prefijo.length));
      }
    }
    for (final bookId in pendientes) {
      await obtener(bookId);
    }
  }

  Map<String, dynamic>? _leerLocal(SharedPreferences prefs, String clave) {
    final raw = prefs.getString(clave);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _subir(
    SharedPreferences prefs,
    String clave,
    String bookId,
    Map<String, dynamic> kit,
  ) async {
    final fecha = await _remoto.escribir(bookId.trim(), kit);
    if (fecha == null) return;
    final ms = fecha.millisecondsSinceEpoch;
    await prefs.setInt('$clave$_sufijoFecha', ms);
    await prefs.setInt('$clave$_sufijoSync', ms);
  }
}
