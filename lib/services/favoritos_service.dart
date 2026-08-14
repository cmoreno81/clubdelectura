import 'package:flutter/foundation.dart';
import '../models/perfil_usuario.dart';
import 'api_service.dart';
import 'usuario_service.dart';

/// Singleton que mantiene los libros favoritos del usuario actual en memoria.
/// Usar [ListenableBuilder] para reaccionar a cambios.
class FavoritosService extends ChangeNotifier {
  FavoritosService._();
  static final FavoritosService instance = FavoritosService._();

  List<LibroFavorito> _favoritos = [];
  bool _cargado = false;

  List<LibroFavorito> get favoritos => List.unmodifiable(_favoritos);

  int get total => _favoritos.length;

  bool isFavorito(String bookId) =>
      _favoritos.any((f) => f.id == bookId);

  bool get lleno => _favoritos.length >= 5;

  /// Carga los favoritos del usuario actual (solo si no están ya cargados).
  Future<void> cargar({bool forzar = false}) async {
    if (_cargado && !forzar) return;
    try {
      final usuario = await UsuarioService().obtenerUsuario();
      if (usuario == null || usuario.trim().isEmpty) return;
      final lista = await ApiService().getFavoritosUsuario(usuario.trim());
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
    final eraFavorito = isFavorito(bookId);

    if (!eraFavorito && lleno) {
      return (ok: false, mensaje: 'Ya tienes 5 favoritos. Quita uno antes de añadir otro.', isFavorite: false);
    }

    // Optimistic update
    if (eraFavorito) {
      _favoritos.removeWhere((f) => f.id == bookId);
    } else {
      _favoritos = [
        ..._favoritos,
        LibroFavorito(id: bookId, title: title, coverUrl: coverUrl, authorName: authorName),
      ];
    }
    notifyListeners();

    try {
      final respuesta = await ApiService().toggleFavorito(bookId);
      final ok = respuesta['ok'] == true;
      final mensaje = respuesta['mensaje']?.toString() ?? '';

      if (!ok) {
        // Revertir si el servidor rechazó
        if (eraFavorito) {
          _favoritos = [
            ..._favoritos,
            LibroFavorito(id: bookId, title: title, coverUrl: coverUrl, authorName: authorName),
          ];
        } else {
          _favoritos.removeWhere((f) => f.id == bookId);
        }
        notifyListeners();
        return (ok: false, mensaje: mensaje, isFavorite: eraFavorito);
      }

      return (ok: true, mensaje: mensaje, isFavorite: !eraFavorito);
    } catch (e) {
      // Revertir en error de red
      if (eraFavorito) {
        _favoritos = [
          ..._favoritos,
          LibroFavorito(id: bookId, title: title, coverUrl: coverUrl, authorName: authorName),
        ];
      } else {
        _favoritos.removeWhere((f) => f.id == bookId);
      }
      notifyListeners();
      return (ok: false, mensaje: 'Error de conexión', isFavorite: eraFavorito);
    }
  }

  void resetear() {
    _favoritos = [];
    _cargado = false;
    notifyListeners();
  }
}
