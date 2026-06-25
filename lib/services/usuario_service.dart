import 'package:shared_preferences/shared_preferences.dart';

class UsuarioService {

  static const _claveUsuario =
      'usuario_actual';

  Future<void> guardarUsuario(
    String usuario,
  ) async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _claveUsuario,
      usuario,
    );
  }

  Future<String?> obtenerUsuario() async {

    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _claveUsuario,
    );
  }

  Future<void> borrarUsuario() async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _claveUsuario,
    );
  }
}