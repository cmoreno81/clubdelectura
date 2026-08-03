import 'package:flutter/foundation.dart';

/// Notifica que una operación externa ha cambiado las sagas de la usuaria.
class SeriesRefreshNotifier extends ChangeNotifier {
  SeriesRefreshNotifier._();

  static final SeriesRefreshNotifier instance = SeriesRefreshNotifier._();

  void invalidate() => notifyListeners();
}
