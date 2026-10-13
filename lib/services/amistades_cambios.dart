import 'package:flutter/foundation.dart';

/// Avisa a las tarjetas de Inicio de que las amistades han cambiado (se
/// aceptó o envió una solicitud, se quitó a alguien…) para que se vuelvan a
/// cargar sin tener que reiniciar la app.
class AmistadesCambios {
  AmistadesCambios._();

  static final ValueNotifier<int> cambios = ValueNotifier<int>(0);

  static void avisar() => cambios.value++;
}
