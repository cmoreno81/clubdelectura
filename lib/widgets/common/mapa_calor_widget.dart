import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Mapa de calor estilo book-journal — muestra la actividad lectora del año
/// con una cuadrícula de 12 meses × 31 días, inspirada en los reading trackers
/// de bullet journal.
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
        height: 140,
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
            _PillStat(value: _totalDias, label: 'días leídos'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _CalendarioMeses(year: year, levels: _levels!),
        const SizedBox(height: AppSpacing.sm),
        _Leyenda(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat pill
// ─────────────────────────────────────────────────────────────────────────────

class _PillStat extends StatelessWidget {
  const _PillStat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primary.withValues(alpha: .8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cuadrícula meses × días (estilo bullet-journal)
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarioMeses extends StatelessWidget {
  const _CalendarioMeses({required this.year, required this.levels});

  final int year;
  final Map<String, int> levels;

  static const _months = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Solo pintamos hasta el mes actual si es el año en curso
    final lastMonth = (year == now.year) ? now.month : 12;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Celda: dejamos 20px para la etiqueta de día (izq) + 12 columnas de mes
        const labelW = 20.0;
        final available = constraints.maxWidth - labelW;
        final cellW = (available / 12).clamp(10.0, 28.0);
        const cellH = 10.0;
        const gap = 1.5;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: labelW + 12 * (cellW + gap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabecera de meses ────────────────────────────────────────
                Row(
                  children: [
                    SizedBox(width: labelW),
                    ...List.generate(12, (mi) {
                      final isPast = mi + 1 <= lastMonth;
                      return SizedBox(
                        width: cellW + gap,
                        child: Text(
                          _months[mi],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isPast
                                ? AppColors.textSecondary
                                : AppColors.textMuted.withValues(alpha: .4),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 3),
                // ── Filas de días ─────────────────────────────────────────────
                ...List.generate(31, (di) {
                  final day = di + 1;
                  final showLabel = day == 1 || day == 5 || day == 10 ||
                      day == 15 || day == 20 || day == 25 || day == 31;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: gap),
                    child: Row(
                      children: [
                        // Etiqueta de día
                        SizedBox(
                          width: labelW,
                          child: showLabel
                              ? Text(
                                  '$day',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: AppColors.textMuted,
                                  ),
                                )
                              : null,
                        ),
                        // Celdas de cada mes
                        ...List.generate(12, (mi) {
                          final month = mi + 1;
                          final daysInMonth = DateTime(year, month + 1, 0).day;
                          final isPast = mi + 1 <= lastMonth;

                          if (day > daysInMonth) {
                            // Día no existe en este mes → vacío
                            return SizedBox(width: cellW + gap, height: cellH);
                          }

                          final key =
                              '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                          final level = levels[key] ?? 0;
                          final isFuture = !isPast ||
                              (year == now.year &&
                                  month == now.month &&
                                  day > now.day);

                          return Padding(
                            padding: const EdgeInsets.only(right: gap),
                            child: _Cell(
                              level: level,
                              isFuture: isFuture,
                              cellW: cellW,
                              cellH: cellH,
                              date: DateTime(year, month, day),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.level,
    required this.isFuture,
    required this.cellW,
    required this.cellH,
    required this.date,
  });

  final int level;
  final bool isFuture;
  final double cellW;
  final double cellH;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _label(),
      child: Container(
        width: cellW,
        height: cellH,
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
    const labels = ['', 'Algo de actividad', 'Día lector', 'Muy activa', '¡Día increíble!'];
    return '$day — ${labels[level.clamp(0, 4)]}';
  }

  Color _color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isFuture) {
      // Días futuros: muy sutil, distinguibles de los pasados sin actividad
      return isDark
          ? const Color(0xFF1A1A1A)
          : const Color(0xFFF0F0F0);
    }

    if (level == 0) {
      // Día pasado sin actividad
      return isDark ? const Color(0xFF2A2020) : const Color(0xFFE8E0E0);
    }

    // Niveles 1-4: de rosa claro a morado oscuro, acorde con la paleta de la app
    const shades = [
      Color(0xFFE8C1D8), // nivel 1 — muy claro
      Color(0xFFC87FB0), // nivel 2
      Color(0xFF9B4F8A), // nivel 3
      Color(0xFF6B2260), // nivel 4 — oscuro
    ];
    return shades[(level - 1).clamp(0, 3)];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leyenda
// ─────────────────────────────────────────────────────────────────────────────

class _Leyenda extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Sin actividad', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        const SizedBox(width: AppSpacing.xs),
        ...List.generate(4, (i) => Padding(
          padding: const EdgeInsets.only(left: 3),
          child: _Cell(
            level: i + 1,
            isFuture: false,
            cellW: 11,
            cellH: 11,
            date: DateTime.now(),
          ),
        )),
        const SizedBox(width: AppSpacing.xs),
        Text('Muy activa', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}
