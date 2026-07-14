import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/atmosferas/atmosfera_resolver.dart';
import '../theme/atmosferas/atmosfera_tipo.dart';

class AtmosferaController extends ChangeNotifier {
  static const _claveAnimaciones = 'atmosfera_animaciones_activas';

  AtmosferaLectura _lectura = AtmosferaLectura.neutra;
  DateTime? _fechaForzada;
  bool _animacionesActivas = true;

  String? _bookIdActivo;

  AtmosferaController() {
    _restaurarPreferencias();
  }

  AtmosferaLectura get lectura => _lectura;

  DateTime? get fechaForzada => _fechaForzada;

  bool get animacionesActivas => _animacionesActivas;

  String? get bookIdActivo => _bookIdActivo;

  bool get hayLibroActivo {
    return _bookIdActivo != null && _bookIdActivo!.trim().isNotEmpty;
  }

  AtmosferaVisual get visual {
    return AtmosferaResolver.resolver(lectura: _lectura, fecha: _fechaForzada);
  }

  Future<void> _restaurarPreferencias() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _animacionesActivas = prefs.getBool(_claveAnimaciones) ?? true;

      notifyListeners();
    } catch (error) {
      debugPrint('No se pudo restaurar la preferencia de animaciones: $error');
    }
  }

  void entrarEnLibro({required String bookId, required String atmosferaId}) {
    _bookIdActivo = bookId.trim().isEmpty ? null : bookId.trim();

    _lectura = AtmosferaLecturaParser.fromApi(atmosferaId);

    notifyListeners();
  }

  void aplicarAtmosferaLibro({
    required String bookId,
    required AtmosferaLectura atmosfera,
  }) {
    _bookIdActivo = bookId.trim().isEmpty ? null : bookId.trim();
    _lectura = atmosfera;

    notifyListeners();
  }

  void actualizarAtmosferaLibro(AtmosferaLectura atmosfera) {
    if (_lectura == atmosfera) return;

    _lectura = atmosfera;
    notifyListeners();
  }

  void salirDelLibro({String? bookId}) {
    final idQueSale = bookId?.trim();

    if (idQueSale != null &&
        idQueSale.isNotEmpty &&
        _bookIdActivo != idQueSale) {
      return;
    }

    _bookIdActivo = null;
    _lectura = AtmosferaLectura.neutra;
    _fechaForzada = null;

    notifyListeners();
  }

  void usarAtmosferaNeutra() {
    _bookIdActivo = null;
    _lectura = AtmosferaLectura.neutra;
    _fechaForzada = null;

    notifyListeners();
  }

  Future<void> cambiarAnimaciones(bool activas) async {
    if (_animacionesActivas == activas) return;

    _animacionesActivas = activas;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_claveAnimaciones, activas);
    } catch (error) {
      debugPrint('No se pudo guardar la opción de animaciones: $error');
    }
  }

  void forzarFecha(DateTime? fecha) {
    _fechaForzada = fecha;
    notifyListeners();
  }

  void usarFechaActual() {
    if (_fechaForzada == null) return;

    _fechaForzada = null;
    notifyListeners();
  }

  void probar({required AtmosferaLectura lectura, DateTime? fecha}) {
    _lectura = lectura;
    _fechaForzada = fecha;

    notifyListeners();
  }
}
