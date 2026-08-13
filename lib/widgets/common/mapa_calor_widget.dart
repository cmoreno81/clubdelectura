import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Mapa de calor estilo GitHub — muestra la actividad lectora del año.
///
/// Carga los datos de forma autónoma desde el API.
class MapaCalorWidget extends StatefulWidget {
  const MapaCalorWidget({super.key, this.anio});

  final int? anio;

  @override
  State<MapaCalorWidget> createState() => _MapaCalorWidgetState();
}

class _MapaCalorWidgetState extends State<MapaCalorWidget> {
  Map<String, int>? _levels; // "2026-08-13" → nivel 0-4
  int _totalDias = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await ApiService().getMapaCalor(anio: widget.anio);
      final days = data['days'] as List<dynamic>? ?? [];
      final map = <String, int>{};
      for (final d in days) {
        final date = d['date'] as String;
        final level = (d['level'] as num).toInt();
        map[date] = level;
      }
      if (mounted) {
        setState(() {
          _levels = map;
          _totalDias = data['totalActiveDays'] as int? ?? map.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_levels == null) return const SizedBox.shrink();

    final year = widget.anio ?? DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Actividad lectora $year', style: AppTextStyles.subtitle),
            const Spacer(),
            Text(
              '$_totalDias ${_totalDias == 1 ? 'día activo' : 'días activos'}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _CalendarioCalor(year: year, levels: _levels!),
        const SizedBox(height: AppSpacing.xs),
        _Leyenda(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CalendarioCalor extends StatelessWidget {
  const _CalendarioCalor({required this.year, required this.levels});

  final int year;
  final Map<String, int> levels;

  static const _abbrev = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

  @override
  Widget build(BuildContext context) {
    // Construimos 53 semanas × 7 días
    final start = DateTime(year, 1, 1);
    // El primer día de la grilla es el lunes de la semana que contiene el 1-ene
    final firstMonday = start.subtract(Duration(days: (start.weekday - 1) % 7));

    final weeks = <List<DateTime?>>[];
    var cursor = firstMonday;
    while (cursor.year <= year || (cursor.year == year + 1 && cursor.weekday > 1)) {
      final week = <DateTime?>[];
      for (var i = 0; i < 7; i++) {
        week.add(cursor.year == year ? cursor : null);
        cursor = cursor.add(const Duration(days: 1));
      }
      weeks.add(week);
      if (weeks.length > 54) break;
    }

    // Encabezados de mes
    final monthLabels = _buildMonthLabels(firstMonday, weeks.length);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiquetas de mes
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 18), // espacio para labels de día
              ...List.generate(weeks.length, (wi) {
                final label = monthLabels[wi];
                return SizedBox(
                  width: 13,
                  child: label != null
                      ? Text(
                          label,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textMuted,
                          ),
                        )
                      : null,
                );
              }),
            ],
          ),
          const SizedBox(height: 2),
          // Grilla de días
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Días de la semana (L M X J V S D)
              Column(
                children: List.generate(7, (i) => _dayLabel(i)),
              ),
              const SizedBox(width: 2),
              // Semanas
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: weeks.map((week) {
                  return Column(
                    children: week.map((day) {
                      if (day == null) return const SizedBox(width: 11, height: 11);
                      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                      final level = levels[key] ?? 0;
                      return _Cell(level: level, date: day);
                    }).toList(),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayLabel(int i) {
    const labels = ['L', '', 'X', '', 'V', '', 'D'];
    return SizedBox(
      width: 14,
      height: 11,
      child: Text(
        labels[i],
        style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
        textAlign: TextAlign.right,
      ),
    );
  }

  Map<int, String> _buildMonthLabels(DateTime firstMonday, int numWeeks) {
    final result = <int, String>{};
    var current = firstMonday;
    var prevMonth = -1;
    for (var wi = 0; wi < numWeeks; wi++) {
      if (current.month != prevMonth && current.year == year) {
        result[wi] = _abbrev[current.month - 1];
        prevMonth = current.month;
      }
      current = current.add(const Duration(days: 7));
    }
    return result;
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.level, required this.date});

  final int level;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _label(),
      child: Container(
        width: 11,
        height: 11,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _color(context),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  String _label() {
    final day = '${date.day}/${date.month}/${date.year}';
    if (level == 0) return day;
    const labels = ['', 'Algo de actividad', 'Actividad lectora', 'Muy activo', '¡Día lector increíble!'];
    return '$day — ${labels[level.clamp(0, 4)]}';
  }

  Color _color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (level == 0) {
      return isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEEEEEE);
    }
    // Verde azulado, como GitHub pero con tono más libresco
    const shades = [
      Color(0xFF9BE9A8),
      Color(0xFF40C463),
      Color(0xFF30A14E),
      Color(0xFF216E39),
    ];
    return shades[(level - 1).clamp(0, 3)];
  }
}

class _Leyenda extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Menos', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(width: AppSpacing.xs),
        ...List.generate(5, (i) => _Cell(level: i, date: DateTime.now())),
        const SizedBox(width: AppSpacing.xs),
        Text('Más', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}
