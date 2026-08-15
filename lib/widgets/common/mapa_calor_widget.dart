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
  const MapaCalorWidget({super.key, this.anio, this.loadData});

  final int? anio;
  final Future<Map<String, dynamic>> Function(int? year)? loadData;

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
      final data =
          await (widget.loadData?.call(widget.anio) ??
              ApiService().getMapaCalor(anio: widget.anio));
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
        _ActivityHeader(year: year, totalDays: _totalDias),
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

class _ActivityHeader extends StatelessWidget {
  const _ActivityHeader({required this.year, required this.totalDays});

  final int year;
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    final title = 'Actividad de lectura $year';
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final titlePainter = TextPainter(
      text: TextSpan(text: title, style: AppTextStyles.subtitle),
      textDirection: direction,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final pillPainter = TextPainter(
      text: TextSpan(
        text: '$totalDays ${totalDays == 1 ? 'día leído' : 'días leídos'}',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      textDirection: direction,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.sm;
        final pillWidth = pillPainter.width + 20;
        final fitsInOneLine =
            titlePainter.width + spacing + pillWidth <= constraints.maxWidth;

        if (!fitsInOneLine) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.sm),
              _PillStat(value: totalDays),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: Text(title, style: AppTextStyles.subtitle)),
            const SizedBox(width: spacing),
            _PillStat(value: totalDays),
          ],
        );
      },
    );
  }
}

class _PillStat extends StatelessWidget {
  const _PillStat({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            TextSpan(
              text: value == 1 ? 'día leído' : 'días leídos',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary.withValues(alpha: .8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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

  static const _months = [
    'E',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Solo pintamos hasta el mes actual si es el año en curso
    final lastMonth = (year == now.year) ? now.month : 12;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Dejamos espacio para la etiqueta lateral y descontamos también las
        // separaciones: no deben sumarse después al ancho ya distribuido.
        const labelW = 20.0;
        const gap = 1.5;
        const minCellW = 10.0;
        const maxCellW = 28.0;
        const cellH = 10.0;
        const columns = 12;
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : labelW + columns * (maxCellW + gap);
        final cellW = ((maxWidth - labelW - columns * gap) / columns).clamp(
          minCellW,
          maxCellW,
        );
        final contentWidth = labelW + columns * (cellW + gap);
        final needsScroll = contentWidth > maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: needsScroll
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: contentWidth,
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
                  final showLabel =
                      day == 1 ||
                      day == 5 ||
                      day == 10 ||
                      day == 15 ||
                      day == 20 ||
                      day == 25 ||
                      day == 31;
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
                          final isFuture =
                              !isPast ||
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
    const labels = [
      '',
      'Algo de actividad',
      'Día lector',
      'Muy activa',
      '¡Día increíble!',
    ];
    return '$day — ${labels[level.clamp(0, 4)]}';
  }

  Color _color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isFuture) {
      // Días futuros: muy sutil, distinguibles de los pasados sin actividad
      return isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0);
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
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        Text(
          'Sin actividad',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
        Wrap(
          spacing: 3,
          children: List.generate(
            4,
            (i) => _Cell(
              level: i + 1,
              isFuture: false,
              cellW: 11,
              cellH: 11,
              date: DateTime.now(),
            ),
          ),
        ),
        Text(
          'Muy activa',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
