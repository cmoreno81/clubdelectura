import 'package:flutter/widgets.dart';

/// Puente entre la pantalla de Inicio (que sabe navegar a Catálogo, Ligas,
/// Mi club o Ajustes) y la barra lateral de las tablets, que vive fuera del
/// navegador. Mientras Inicio está montada, la barra lateral se muestra y sus
/// toques se reenvían a Inicio.
class ShellNavegacion extends ChangeNotifier {
  ShellNavegacion._();

  static final ShellNavegacion instance = ShellNavegacion._();

  Object? _dueno;
  void Function(int indice)? _alSeleccionar;
  int _seleccion = 0;
  bool _tieneClub = false;

  /// Hay una pantalla de Inicio montada que atiende la barra lateral.
  bool get activo => _alSeleccionar != null;

  /// Sección marcada en la barra lateral: la de la pantalla que la fuerza
  /// (p. ej. Mi club al estar dentro de él) o, si no, la de Inicio.
  int get seleccion => _forzada ?? _seleccion;
  int? _forzada;
  Object? _duenoForzada;

  /// Una pantalla que no es de Inicio marca su sección mientras está abierta.
  void marcarSeccion(Object dueno, int indice) {
    _duenoForzada = dueno;
    _forzada = indice;
    _avisar();
  }

  void soltarSeccion(Object dueno) {
    if (_duenoForzada != dueno) return;
    _duenoForzada = null;
    _forzada = null;
    _avisar();
  }

  bool get tieneClub => _tieneClub;

  void registrar(
    Object dueno, {
    required void Function(int indice) alSeleccionar,
  }) {
    _dueno = dueno;
    _alSeleccionar = alSeleccionar;
    _avisar();
  }

  void liberar(Object dueno) {
    if (_dueno != dueno) return;
    _dueno = null;
    _alSeleccionar = null;
    _avisar();
  }

  void actualizar({required int seleccion, required bool tieneClub}) {
    if (seleccion == _seleccion && tieneClub == _tieneClub) return;
    _seleccion = seleccion;
    _tieneClub = tieneClub;
    _avisar();
  }

  void seleccionar(int indice) => _alSeleccionar?.call(indice);

  // Registrar/actualizar ocurre durante la construcción de pantallas: los
  // oyentes se avisan después del fotograma para no reconstruir en pleno build.
  bool _pendiente = false;
  void _avisar() {
    if (_pendiente) return;
    _pendiente = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendiente = false;
      notifyListeners();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}
