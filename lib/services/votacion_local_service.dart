import 'package:shared_preferences/shared_preferences.dart';
import 'auth_session_service.dart';

class VotacionLocalService {
  String get _clave =>
      'ultima_votacion_${AuthSessionService.instance.user?.id ?? 'anonymous'}';

  Future<void> guardarVoto(String idVotacion) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_clave, idVotacion);
  }

  Future<bool> haVotado(String idVotacion) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_clave) == idVotacion;
  }

  Future<void> borrar() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_clave);
  }
}
