abstract final class LecturaFechaUtils {
  static const _meses = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sept',
    'oct',
    'nov',
    'dic',
  ];

  /// Admite fechas del perfil (`dd/MM/yyyy`) y fechas ISO del API
  /// (`yyyy-MM-dd` o `yyyy-MM-ddTHH:mm:ss...`).
  static DateTime? parse(String texto) {
    final valor = texto.trim();

    if (valor.isEmpty) return null;

    final formatoPerfil = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})$',
    ).firstMatch(valor);

    if (formatoPerfil != null) {
      return _fechaValida(
        anio: int.parse(formatoPerfil.group(3)!),
        mes: int.parse(formatoPerfil.group(2)!),
        dia: int.parse(formatoPerfil.group(1)!),
      );
    }

    final formatoIso = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:T|\s|$)',
    ).firstMatch(valor);

    if (formatoIso != null) {
      return _fechaValida(
        anio: int.parse(formatoIso.group(1)!),
        mes: int.parse(formatoIso.group(2)!),
        dia: int.parse(formatoIso.group(3)!),
      );
    }

    return null;
  }

  static String rango(String inicio, String fin) {
    final fechaInicio = parse(inicio);
    final fechaFin = parse(fin);

    if (fechaInicio == null && fechaFin == null) return '';

    if (fechaInicio == null) {
      return _formatear(fechaFin!, incluirAnio: true);
    }

    if (fechaFin == null) {
      return _formatear(fechaInicio, incluirAnio: true);
    }

    final mismoAnio = fechaInicio.year == fechaFin.year;

    return '${_formatear(fechaInicio, incluirAnio: !mismoAnio)} → '
        '${_formatear(fechaFin, incluirAnio: true)}';
  }

  static String duracion(String inicio, String fin) {
    final fechaInicio = parse(inicio);
    final fechaFin = parse(fin);

    if (fechaInicio == null ||
        fechaFin == null ||
        fechaFin.isBefore(fechaInicio)) {
      return '';
    }

    final dias = fechaFin.difference(fechaInicio).inDays + 1;

    if (dias == 1) return '⚡ Devorado en un día';

    if (dias <= 3) return '⚡ Devorado en $dias días';

    if (dias <= 14) return '📖 Leído en $dias días';

    if (dias <= 30) return '☕ Disfrutado durante $dias días';

    return '🌿 Acompañó $dias días de lectura';
  }

  static DateTime? _fechaValida({
    required int anio,
    required int mes,
    required int dia,
  }) {
    if (anio < 1 || mes < 1 || mes > 12 || dia < 1 || dia > 31) {
      return null;
    }

    final fecha = DateTime(anio, mes, dia);

    if (fecha.year != anio || fecha.month != mes || fecha.day != dia) {
      return null;
    }

    return fecha;
  }

  static String _formatear(DateTime fecha, {required bool incluirAnio}) {
    final base =
        '${fecha.day.toString().padLeft(2, '0')} '
        '${_meses[fecha.month - 1]}';

    return incluirAnio ? '$base ${fecha.year}' : base;
  }
}
