import 'package:shared_preferences/shared_preferences.dart';

class LibraryOrderPreferences {
  const LibraryOrderPreferences();

  static const _prefix = 'library_order_';

  Future<String?> read(String userId) async {
    final normalized = _normalizedUserId(userId);
    if (normalized.isEmpty) return null;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('$_prefix$normalized');
  }

  Future<void> write(String userId, String order) async {
    final normalized = _normalizedUserId(userId);
    if (normalized.isEmpty || order.trim().isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('$_prefix$normalized', order.trim());
  }

  String _normalizedUserId(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
  }
}
