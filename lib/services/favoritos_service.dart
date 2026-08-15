import 'package:flutter/foundation.dart';
import '../models/perfil_usuario.dart';
import 'api_service.dart';
import 'usuario_service.dart';

/// Singleton que mantiene los libros favoritos del usuario actual en memoria.
/// Usar [ListenableBuilder] para reaccionar a cambios.
class FavoritosService extends ChangeNotifier {
  FavoritosService._({ApiService? apiService})
    : _apiService = apiService ?? ApiService();
  static final FavoritosService instance = FavoritosService._();

  @visibleForTesting
  factory FavoritosService.forTesting(ApiService apiService) =>
      FavoritosService._(apiService: apiService);

  final ApiService _apiService;

  List<LibroFavorito> _favoritos = [];
  bool _cargado = false;
  bool _operando = false;

  List<LibroFavorito> get favoritos => List.unmodifiable(_favoritos);

  int get total => _favoritos.length;

  bool isFavorito(String bookId) => _favoritos.any((f) => f.id == bookId);

  bool get lleno => _favoritos.length >= 5;
  bool get operando => _operando;
  bool get cargado => _cargado;

  /// Carga los favoritos del usuario actual (solo si no están ya cargados).
  Future<void> cargar({bool forzar = false}) async {
    if (_cargado && !forzar) return;
    try {
      final usuario = await UsuarioService().obtenerUsuario();
      if (usuario == null || usuario.trim().isEmpty) return;
      final lista = await _apiService.getFavoritosUsuario(usuario.trim());
      _favoritos = lista;
      _cargado = true;
      notifyListeners();
    } catch (_) {}
  }

  /// Alterna el favorito para [bookId]. Devuelve el nuevo estado (true = es favorito).
  /// Hace optimistic update: cambia el estado local antes de la respuesta.
  Future<({bool ok, String mensaje, bool isFavorite})> toggle(
    String bookId,
    String title, {
    String? coverUrl,
    String? authorName,
  }) async {
    if (_operando) {
      return (
        ok: false,
        mensaje: 'Hay una operación en curso.',
        isFavorite: isFavorito(bookId),
      );
    }
    final eraFavorito = isFavorito(bookId);

    if (!eraFavorito && lleno) {
      return (
        ok: false,
        mensaje: 'Ya tienes 5 favoritos. Quita uno antes de añadir otro.',
        isFavorite: false,
      );
    }

    final anteriores = List<LibroFavorito>.of(_favoritos);
    _operando = true;
    // Optimistic update
    if (eraFavorito) {
      _favoritos.removeWhere((f) => f.id == bookId);
    } else {
      _favoritos = [
        ..._favoritos,
        LibroFavorito(
          id: bookId,
          title: title,
          coverUrl: coverUrl,
          authorName: authorName,
        ),
      ];
    }
    notifyListeners();

    try {
      final respuesta = await _apiService.toggleFavorito(bookId);
      final ok = respuesta['ok'] == true;
      final mensaje = respuesta['mensaje']?.toString() ?? '';

      if (!ok) {
        _favoritos = anteriores;
        _operando = false;
        notifyListeners();
        return (ok: false, mensaje: mensaje, isFavorite: eraFavorito);
      }

      _operando = false;
      notifyListeners();
      return (ok: true, mensaje: mensaje, isFavorite: !eraFavorito);
    } catch (e) {
      _favoritos = anteriores;
      _operando = false;
      notifyListeners();
      return (ok: false, mensaje: 'Error de conexión', isFavorite: eraFavorito);
    }
  }

  /// Sustituye un favorito conservando su posición. El servidor realiza el
  /// cambio de forma atómica; el estado optimista se revierte íntegro al fallar.
  Future<({bool ok, String mensaje})> reemplazar(
    LibroFavorito actual,
    LibroFavorito nuevo,
  ) async {
    if (_operando) {
      return (ok: false, mensaje: 'Hay una operación en curso.');
    }
    final index = _favoritos.indexWhere((f) => f.id == actual.id);
    if (index < 0) {
      return (
        ok: false,
        mensaje: 'El favorito original ya no está disponible.',
      );
    }
    if (isFavorito(nuevo.id)) {
      return (ok: false, mensaje: 'Ese libro ya es favorito.');
    }

    final anteriores = List<LibroFavorito>.of(_favoritos);
    _operando = true;
    _favoritos = List<LibroFavorito>.of(_favoritos)..[index] = nuevo;
    notifyListeners();

    try {
      final respuesta = await _apiService.reemplazarFavorito(
        actual.id,
        nuevo.id,
      );
      if (respuesta['ok'] != true) {
        _favoritos = anteriores;
        _operando = false;
        notifyListeners();
        return (
          ok: false,
          mensaje:
              respuesta['mensaje']?.toString() ??
              'No se pudo cambiar el favorito.',
        );
      }
      final favorito = respuesta['favorito'];
      if (favorito is Map<String, dynamic>) {
        _favoritos = List<LibroFavorito>.of(_favoritos)
          ..[index] = LibroFavorito.fromJson(favorito);
      }
      _operando = false;
      notifyListeners();
      return (
        ok: true,
        mensaje: respuesta['mensaje']?.toString() ?? 'Favorito actualizado',
      );
    } catch (_) {
      _favoritos = anteriores;
      _operando = false;
      notifyListeners();
      return (ok: false, mensaje: 'Error de conexión');
    }
  }

  @visibleForTesting
  void establecerFavoritos(List<LibroFavorito> favoritos) {
    _favoritos = List.of(favoritos);
    _cargado = true;
    _operando = false;
    notifyListeners();
  }

  void resetear() {
    _favoritos = [];
    _cargado = false;
    notifyListeners();
  }
}
