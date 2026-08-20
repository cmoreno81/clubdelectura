import 'package:flutter/material.dart';

import '../../navigation/app_page_route.dart';
import '../../pages/monthly_reading_share_page.dart';

import '../../models/general_dashboard.dart';
import '../../models/perfil_usuario.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/reading_cover_calendar.dart';

const _meses = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

class PerfilHistoricoMeses extends StatefulWidget {
  const PerfilHistoricoMeses({
    super.key,
    required this.meses,
    required this.onBookTap,
    this.userName = '',
  });

  final List<PerfilMesLector> meses;
  final String userName;
  final void Function({
    required String title,
    required String bookId,
    required String coverUrl,
  })
  onBookTap;

  @override
  State<PerfilHistoricoMeses> createState() => _PerfilHistoricoMesesState();
}

class _PerfilHistoricoMesesState extends State<PerfilHistoricoMeses> {
  // Mes expandido actualmente (índice en la lista, -1 = ninguno)
  int _expanded = -1;

  @override
  void initState() {
    super.initState();
    // El mes más reciente abierto por defecto
    if (widget.meses.isNotEmpty) _expanded = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.meses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.meses.length; i++) ...[
          _MesCard(
            mes: widget.meses[i],
            index: i,
            expanded: _expanded == i,
            onToggle: () => setState(() => _expanded = _expanded == i ? -1 : i),
            onBookTap: widget.onBookTap,
            userName: widget.userName,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _MesCard extends StatelessWidget {
  const _MesCard({
    required this.mes,
    required this.index,
    required this.expanded,
    required this.onToggle,
    required this.onBookTap,
    this.userName = '',
  });

  final PerfilMesLector mes;
  final int index;
  final bool expanded;
  final VoidCallback onToggle;
  final String userName;
  final void Function({
    required String title,
    required String bookId,
    required String coverUrl,
  })
  onBookTap;

  @override
  Widget build(BuildContext context) {
    final label = '${_meses[(mes.mes - 1).clamp(0, 11)]} ${mes.anio}';
    final n = mes.lecturas.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Cabecera ──
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$n ${n == 1 ? 'libro leído' : 'libros leídos'}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón compartir para los 2 meses más recientes
                      if (index <= 1 && mes.lecturas.isNotEmpty)
                        IconButton(
                          tooltip: 'Compartir mes lector',
                          icon: const Icon(Icons.ios_share_rounded, size: 18),
                          color: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.push<void>(
                            context,
                            AppPageRoute(
                              builder: (_) => MonthlyReadingSharePage(
                                calendar: _buildCalendar(),
                                userName: userName,
                              ),
                            ),
                          ),
                        ),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Calendario expandible ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: ReadingCoverCalendar(
                calendar: _buildCalendar(),
                showMonthHeader: false,
                onBookTap: (reading) => onBookTap(
                  title: reading.title,
                  bookId: reading.bookId,
                  coverUrl: reading.coverUrl,
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  ReadingCalendar _buildCalendar() {
    // Convierte PerfilMesLectura → MonthlyReadingSpan para reutilizar
    // el ReadingCoverCalendar existente
    final readings = mes.lecturas
        .map(
          (l) => MonthlyReadingSpan(
            id: l.id,
            libraryId: '',
            bookId: l.bookId,
            title: l.titulo,
            coverUrl: l.coverUrl,
            startedAt: _toIso(l.fechaInicio),
            finishedAt: _toIso(l.fechaFin),
          ),
        )
        .toList(growable: false);

    final finishedBooks = mes.lecturas
        .map(
          (l) => MonthlyFinishedBook(
            id: l.id,
            bookId: l.bookId,
            title: l.titulo,
            coverUrl: l.coverUrl,
            finishedAt: _toIso(l.fechaFin),
            pages: 0,
            rating: l.valoracion,
          ),
        )
        .toList(growable: false);

    return ReadingCalendar(
      year: mes.anio,
      month: mes.mes,
      events: const [],
      readings: readings,
      finishedBooks: finishedBooks,
    );
  }

  /// Convierte dd/mm/yyyy → yyyy-mm-dd para que DateTime.tryParse funcione
  String _toIso(String fecha) {
    final parts = fecha.split('/');
    if (parts.length != 3) return fecha;
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }
}
