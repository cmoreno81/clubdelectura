import 'auth_session_service.dart';

class UsuarioService {
  /// Compatibilidad para las vistas antiguas. La identidad procede siempre de
  /// la sesión autenticada, nunca de un valor elegido o almacenado por la APK.
  Future<String?> obtenerUsuario() async {
    await AuthSessionService.instance.initialize();
    return AuthSessionService.instance.user?.nombre.trim();
  }

  Future<void> borrarUsuario() => AuthSessionService.instance.clear();
}
