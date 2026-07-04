class FechaRelativa {
  static String formato(String fecha) {
    try {
      final d = DateTime.parse(fecha.replaceFirst(" ", "T"));

      final diff = DateTime.now().difference(d);

      if (diff.inMinutes < 1) {
        return "Ahora mismo";
      }

      if (diff.inMinutes < 60) {
        return "Hace ${diff.inMinutes} min";
      }

      if (diff.inHours < 24) {
        return "Hace ${diff.inHours} h";
      }

      if (diff.inDays == 1) {
        return "Ayer";
      }

      return "Hace ${diff.inDays} días";
    } catch (_) {
      return fecha;
    }
  }
}
