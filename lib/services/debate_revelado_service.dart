import 'package:shared_preferences/shared_preferences.dart';
import 'auth_session_service.dart';

/// Recuerda, por usuaria y por libro, si ya se tocó el aviso de spoiler del
/// "Debate final" — una vez revelado, se entiende que esa persona ya
/// terminó el libro y quiere seguir la conversación, así que no se le
/// vuelve a tapar en sucesivas visitas.
class DebateReveladoService {
  static const _prefix = 'debate_revelado_';

  static String _key(String libro) =>
      '$_prefix${AuthSessionService.instance.user?.id ?? 'anonymous'}_${libro.trim().toLowerCase().replaceAll(' ', '_')}';

  static Future<bool> estaRevelado(String libro) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(libro)) ?? false;
  }

  static Future<void> marcarRevelado(String libro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(libro), true);
  }
}
