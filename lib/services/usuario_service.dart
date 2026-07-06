import 'package:shared_preferences/shared_preferences.dart';

class UsuarioService {
  static const _claveUsuario = 'usuario_actual';
  static SharedPreferences? _prefs;

  Future<SharedPreferences> _preferencias() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> guardarUsuario(String usuario) async {
    final prefs = await _preferencias();

    await prefs.setString(_claveUsuario, usuario.trim());
  }

  Future<String?> obtenerUsuario() async {
    final prefs = await _preferencias();

    return prefs.getString(_claveUsuario)?.trim();
  }

  Future<void> borrarUsuario() async {
    final prefs = await _preferencias();

    await prefs.remove(_claveUsuario);
  }
}
