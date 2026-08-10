import 'package:club_lectura_app/services/libros_data_cache.dart';
import 'package:flutter/foundation.dart';

/// Notifica que una operación externa ha cambiado el contenido de Biblioteca.
class LibraryRefreshNotifier extends ChangeNotifier {
  LibraryRefreshNotifier._();

  static final LibraryRefreshNotifier instance = LibraryRefreshNotifier._();

  int _revision = 0;
  int get revision => _revision;

  void invalidate() {
    LibrosDataCache.instance.invalidate(); // ← añadir
    _revision++;
    notifyListeners();
  }
}
