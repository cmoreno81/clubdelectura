class FechaRelativa {
  static String formato(String? fecha) {
    if (fecha == null || fecha.trim().isEmpty) return 'Sin actividad';
    try {
      final d = DateTime.parse(fecha.replaceFirst(' ', 'T')).toLocal();
      const meses = <String>[
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      final hora = d.hour.toString().padLeft(2, '0');
      final minuto = d.minute.toString().padLeft(2, '0');
      return '${d.day} de ${meses[d.month - 1]} de ${d.year}, $hora:$minuto';
    } catch (_) {
      return 'Actividad sin fecha disponible';
    }
  }
}
