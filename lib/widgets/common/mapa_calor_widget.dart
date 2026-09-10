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
  const MapaCalorWidget({
    super.key,
    this.anio,
    this.loadData,
    this.editable = true,
    this.onChanged,
  });

  final int? anio;
  final Future<Map<String, dynamic>> Function(int? year)? loadData;

  /// Si es `false`, los días se pueden consultar pero no marcar/desmarcar
  /// — para cuando se muestra el mapa de calor de otra persona.
  final bool editable;

  /// Se llama tras marcar o desmarcar un día, para que la pantalla que
  /// contiene este widget pueda refrescar otros sitios que también
  /// muestren la racha (p. ej. el botón de check-in de hoy).
  final VoidCallback? onChanged;

  @override
  State<MapaCalorWidget> createState() => _MapaCalorWidgetState();
}

class _MapaCalorWidgetState extends State<MapaCalorWidget> {
  Map<String, int>? _levels; // "2026-08-13" → nivel 0-4
  Map<String, int> _pagesRead = {}; // "2026-08-13" → páginas leídas ese día
  Set<String> _checkedIn = {}; // fechas con check-in explícito
  Map<String, List<String>> _finishedBooks = {}; // fecha → títulos terminados
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
      final pages = <String, int>{};
      final checked = <String>{};
      final finished = <String, List<String>>{};
      for (final d in days) {
        final date = d['date'] as String;
        map[date] = (d['level'] as num).toInt();
        pages[date] = (d['pagesRead'] as num?)?.toInt() ?? 0;
        if (d['checkedIn'] == true) checked.add(date);
        final librosDia = (d['finishedBooks'] as List<dynamic>?) ?? const [];
        if (librosDia.isNotEmpty) {
          finished[date] = librosDia.map((e) => e.toString()).toList();
        }
      }
      if (mounted) {
        setState(() {
          _levels = map;
          _pagesRead = pages;
          _checkedIn = checked;
          _finishedBooks = finished;
          _totalDias = data['totalActiveDays'] as int? ?? map.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _fmt(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static const _nombresMes = [
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

  static const _rangos = [
    (valor: 'HASTA_50', etiqueta: 'Hasta 50 páginas'),
    (valor: 'DE_50_A_75', etiqueta: '50 – 75 páginas'),
    (valor: 'DE_75_A_100', etiqueta: '75 – 100 páginas'),
    (valor: 'MAS_DE_100', etiqueta: 'Más de 100 páginas'),
  ];

  // El backend guarda el punto medio de cada tramo (ver
  // PAGE_RANGE_REPRESENTATIVE en checkin.service.ts) para poder pintar el
  // nivel real y sumarlo a las estadísticas. Si el número de páginas de un
  // día coincide con uno de estos, es que se marcó eligiendo un tramo, no
  // un número exacto — así que en vez de "60 páginas leídas" (que suena a
  // dato preciso) mostramos el tramo original ("Entre 50 y 75 páginas").
  static const _tramoPorRepresentativo = {
    25: 'Hasta 50 páginas',
    60: 'Entre 50 y 75 páginas',
    85: 'Entre 75 y 100 páginas',
    120: 'Más de 100 páginas',
  };

  Future<void> _abrirDetalleDia(DateTime date) async {
    final dateStr = _fmt(date);
    final pages = _pagesRead[dateStr] ?? 0;
    final librosTerminados = _finishedBooks[dateStr] ?? const [];

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          var checked = _checkedIn.contains(dateStr) || pages > 0;
          var procesando = false;

          Future<void> marcar(String rango) async {
            setSheetState(() => procesando = true);
            try {
              final result = await ApiService().doCheckin(
                fecha: dateStr,
                rango: rango,
              );
              if (result['ok'] != true) {
                throw Exception(
                  (result['mensaje'] as String?) ??
                      'No se ha podido guardar el cambio',
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
              await _cargar();
              widget.onChanged?.call();
            } catch (error) {
              if (!ctx.mounted) return;
              setSheetState(() => procesando = false);
              final mensaje = error.toString().replaceFirst('Exception: ', '');
              ScaffoldMessenger.of(
                ctx,
              ).showSnackBar(SnackBar(content: Text(mensaje)));
            }
          }

          Future<void> quitarMarca() async {
            setSheetState(() => procesando = true);
            try {
              final result = await ApiService().undoCheckin(fecha: dateStr);
              if (result['ok'] != true) {
                throw Exception(
                  (result['mensaje'] as String?) ??
                      'No se ha podido guardar el cambio',
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
              await _cargar();
              widget.onChanged?.call();
            } catch (error) {
              if (!ctx.mounted) return;
              setSheetState(() => procesando = false);
              final mensaje = error.toString().replaceFirst('Exception: ', '');
              ScaffoldMessenger.of(
                ctx,
              ).showSnackBar(SnackBar(content: Text(mensaje)));
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(ctx).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  '${date.day} de ${_nombresMes[date.month - 1]}',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  pages > 0
                      ? (_tramoPorRepresentativo[pages] != null
                            ? '📖 ${_tramoPorRepresentativo[pages]} ese día'
                            : '📖 $pages ${pages == 1 ? 'página leída' : 'páginas leídas'} ese día')
                      : checked
                      ? '✅ Marcado como día leído'
                      : 'Sin actividad registrada ese día',
                  style: AppTextStyles.bodySecondary,
                ),
                if (librosTerminados.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    librosTerminados.length == 1
                        ? '🎉 Terminaste "${librosTerminados.first}"'
                        : '🎉 Terminaste: ${librosTerminados.join(', ')}',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (widget.editable) ...[
                  const SizedBox(height: 20),
                  Text(
                    checked
                        ? '¿Cuánto leíste ese día? (lo puedes corregir)'
                        : '¿Cuánto leíste ese día?',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final rango in _rangos)
                        OutlinedButton(
                          onPressed: procesando
                              ? null
                              : () => marcar(rango.valor),
                          child: Text(rango.etiqueta),
                        ),
                    ],
                  ),
                  if (checked) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: procesando ? null : quitarMarca,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Quitar marca de leído'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                    ),
                  ],
                  if (procesando) ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
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
        _CalendarioMeses(
          year: year,
          levels: _levels!,
          finishedDates: _finishedBooks.keys.toSet(),
          onDayTap: _abrirDetalleDia,
        ),
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
  const _CalendarioMeses({
    required this.year,
    required this.levels,
    this.finishedDates = const {},
    this.onDayTap,
  });

  final int year;
  final Map<String, int> levels;

  /// Fechas ("2026-08-13") en las que se terminó algún libro — se marcan en
  /// la celda como incentivo.
  final Set<String> finishedDates;
  final ValueChanged<DateTime>? onDayTap;

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

                          final cellDate = DateTime(year, month, day);
                          return Padding(
                            padding: const EdgeInsets.only(right: gap),
                            child: _Cell(
                              level: level,
                              isFuture: isFuture,
                              finished: finishedDates.contains(key),
                              cellW: cellW,
                              cellH: cellH,
                              date: cellDate,
                              onTap: isFuture || onDayTap == null
                                  ? null
                                  : () => onDayTap!(cellDate),
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
    this.finished = false,
    this.onTap,
  });

  final int level;
  final bool isFuture;
  final double cellW;
  final double cellH;
  final DateTime date;

  /// Ese día se terminó algún libro — se marca con un borde dorado como
  /// pequeño incentivo, sin depender de caber un icono en una celda de
  /// pocos píxeles.
  final bool finished;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _label(),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: cellW,
          height: cellH,
          decoration: BoxDecoration(
            color: _color(context),
            borderRadius: BorderRadius.circular(2),
            border: finished
                ? Border.all(color: const Color(0xFFD39B24), width: 1.4)
                : null,
          ),
        ),
      ),
    );
  }

  String _label() {
    final day = '${date.day}/${date.month}/${date.year}';
    if (level == 0 && !finished) return day;
    const labels = [
      '',
      'Algo de actividad',
      'Día lector',
      'Muy activa',
      '¡Día increíble!',
    ];
    final base = level > 0 ? '$day — ${labels[level.clamp(0, 4)]}' : day;
    return finished ? '$base 🎉 Terminaste un libro' : base;
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
        // Agrupados en una sola fila para que el Wrap no los separe en
        // líneas distintas cuando falta espacio. El texto va en un
        // Flexible para que, con poco ancho o letra ampliada, se envuelva
        // dentro de su propia fila en vez de desbordarla.
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Cell(
              level: 1,
              isFuture: false,
              finished: true,
              cellW: 11,
              cellH: 11,
              date: DateTime.now(),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Libro terminado',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
