import 'package:flutter/material.dart';

import '../../models/perfil_usuario.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/genero_utils.dart';
import '../../utils/lectura_fecha_utils.dart';
import '../common/club_card.dart';
import '../common/club_rating_stars.dart';

class PerfilTimelineLectura extends StatelessWidget {
  final List<PerfilLibroTerminado> libros;
  final List<PerfilSaga> sagas;
  final ValueChanged<PerfilLibroTerminado>? onBookTap;

  const PerfilTimelineLectura({
    super.key,
    required this.libros,
    required this.sagas,
    this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final grupos = _agruparPorAnio(libros);
    final sagasPorAnio = _agruparSagasCompletadasPorAnio();
    final years = {...grupos.keys, ...sagasPorAnio.keys}.toList()
      ..sort((left, right) => right.compareTo(left));

    if (years.isEmpty) {
      return ClubCard(
        elevated: false,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Todavía no hay fechas registradas',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cuando se añadan fechas a los libros, '
              'su recorrido aparecerá aquí.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      );
    }

    return Column(
      children: years
          .map(
            (year) => _GrupoAnioTimeline(
              anio: year,
              meses: grupos[year] ?? const {},
              sagasCompletadas: sagasPorAnio[year] ?? const [],
              nombreMes: _nombreMes,
              onBookTap: onBookTap,
            ),
          )
          .toList(),
    );
  }

  Map<int, Map<int, List<PerfilLibroTerminado>>> _agruparPorAnio(
    List<PerfilLibroTerminado> libros,
  ) {
    final conFecha = libros
        .map(
          (libro) =>
              (libro: libro, fecha: LecturaFechaUtils.parse(libro.fechaFin)),
        )
        .where((item) => item.fecha != null)
        .toList();

    conFecha.sort((a, b) => b.fecha!.compareTo(a.fecha!));

    final grupos = <int, Map<int, List<PerfilLibroTerminado>>>{};

    for (final item in conFecha) {
      final fecha = item.fecha!;
      grupos.putIfAbsent(fecha.year, () => {});
      grupos[fecha.year]!.putIfAbsent(fecha.month, () => []);
      grupos[fecha.year]![fecha.month]!.add(item.libro);
    }

    return grupos;
  }

  Map<int, List<PerfilSaga>> _agruparSagasCompletadasPorAnio() {
    final result = <int, List<PerfilSaga>>{};

    for (final saga in sagas.where((item) => item.completada)) {
      final volumeIds = saga.volumenes
          .map((volume) => volume.bookId.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      final volumeTitles = saga.volumenes
          .map((volume) => volume.titulo.trim().toLowerCase())
          .where((title) => title.isNotEmpty)
          .toSet();

      final completionDates = libros
          .where(
            (book) =>
                volumeIds.contains(book.bookId.trim()) ||
                volumeTitles.contains(book.libro.trim().toLowerCase()),
          )
          .map((book) => LecturaFechaUtils.parse(book.fechaFin))
          .whereType<DateTime>()
          .toList();

      if (completionDates.isEmpty) continue;
      completionDates.sort();
      final year = completionDates.last.year;
      result.putIfAbsent(year, () => []).add(saga);
    }

    for (final yearSagas in result.values) {
      yearSagas.sort(
        (left, right) =>
            left.nombre.toLowerCase().compareTo(right.nombre.toLowerCase()),
      );
    }
    return result;
  }

  String _nombreMes(int mes) {
    const meses = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];

    if (mes < 1 || mes > 12) {
      return '';
    }

    return meses[mes - 1];
  }
}

class _GrupoAnioTimeline extends StatelessWidget {
  final int anio;
  final Map<int, List<PerfilLibroTerminado>> meses;
  final List<PerfilSaga> sagasCompletadas;
  final String Function(int mes) nombreMes;
  final ValueChanged<PerfilLibroTerminado>? onBookTap;

  const _GrupoAnioTimeline({
    required this.anio,
    required this.meses,
    required this.sagasCompletadas,
    required this.nombreMes,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final total = meses.values.fold<int>(
      0,
      (suma, libros) => suma + libros.length,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            key: PageStorageKey('timeline-$anio'),
            initiallyExpanded: anio == DateTime.now().year,
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
            iconColor: color,
            collapsedIconColor: AppColors.textMuted,
            title: Row(
              children: [
                Text(
                  '$anio',
                  style: AppTextStyles.title.copyWith(
                    color: color,
                    fontSize: 25,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Divider(color: color.withValues(alpha: 0.25))),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      total == 1 ? '1 libro' : '$total libros',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (sagasCompletadas.isNotEmpty)
                      Text(
                        sagasCompletadas.length == 1
                            ? '1 saga completada'
                            : '${sagasCompletadas.length} sagas completadas',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFB48113),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            children: [
              if (sagasCompletadas.isNotEmpty) ...[
                _SagasCompletadasHito(sagas: sagasCompletadas),
                const SizedBox(height: AppSpacing.md),
              ],
              for (final mes in meses.entries) ...[
                _GrupoMesTimeline(
                  titulo: nombreMes(mes.key),
                  libros: mes.value,
                  onBookTap: onBookTap,
                ),
                if (mes.key != meses.keys.last)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SagasCompletadasHito extends StatelessWidget {
  const _SagasCompletadasHito({required this.sagas});

  final List<PerfilSaga> sagas;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFB48113);
    return ClubCard(
      elevated: false,
      borderColor: const Color(0xFFE8C76E),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF9E9), Color(0xFFFFEBC0)],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE3A0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sagas.length == 1
                          ? '¡Saga completada!'
                          : '¡${sagas.length} sagas completadas!',
                      style: AppTextStyles.subtitle.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Un universo más que ya forma parte de su historia.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: sagas
                .map(
                  (saga) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: accent.withValues(alpha: .22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: accent,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          saga.nombre,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _GrupoMesTimeline extends StatelessWidget {
  final String titulo;
  final List<PerfilLibroTerminado> libros;
  final ValueChanged<PerfilLibroTerminado>? onBookTap;

  const _GrupoMesTimeline({
    required this.titulo,
    required this.libros,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: color.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: color,
                  size: 19,
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Expanded(
                child: Text(
                  titulo,
                  style: AppTextStyles.subtitle.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  libros.length == 1 ? '1 libro' : '${libros.length} libros',
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          ...List.generate(libros.length, (index) {
            return _TimelineEntrada(
              libro: libros[index],
              esUltima: index == libros.length - 1,
              onTap: onBookTap == null ? null : () => onBookTap!(libros[index]),
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineEntrada extends StatelessWidget {
  final PerfilLibroTerminado libro;
  final bool esUltima;
  final VoidCallback? onTap;

  const _TimelineEntrada({
    required this.libro,
    required this.esUltima,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fechaFin = LecturaFechaUtils.parse(libro.fechaFin);
    final color = Theme.of(context).colorScheme.primary;

    if (fechaFin == null) {
      return const SizedBox.shrink();
    }

    final duracion = LecturaFechaUtils.duracion(
      libro.fechaInicio,
      libro.fechaFin,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Column(
            children: [
              Text(
                fechaFin.day.toString().padLeft(2, '0'),
                style: AppTextStyles.section.copyWith(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              Text(
                _mesCorto(fechaFin.month),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),

              if (!esUltima)
                Container(
                  width: 2,
                  height: 92,
                  color: color.withValues(alpha: 0.16),
                ),
            ],
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: esUltima ? 0 : AppSpacing.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: color.withValues(alpha: 0.10)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: SizedBox(
                        width: 48,
                        height: 68,
                        child: libro.coverUrl.trim().isNotEmpty
                            ? Image.network(
                                libro.coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) {
                                  return _PortadaFallback(color: color);
                                },
                              )
                            : _PortadaFallback(color: color),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.sm),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            libro.libro,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '${iconoGenero(libro.genero)} ${libro.genero}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),

                          if (libro.esRelectura) ...[
                            const SizedBox(height: 4),
                            Text(
                              'RELECTURA',
                              style: AppTextStyles.caption.copyWith(
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],

                          if (libro.valoracion.isNotEmpty) ...[
                            const SizedBox(height: 5),

                            ClubRatingStars(
                              valoracion: libro.valoracion,
                              size: 16,
                              spacing: 0,
                            ),
                          ],

                          if (duracion.isNotEmpty) ...[
                            const SizedBox(height: 5),

                            Text(
                              duracion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _mesCorto(int mes) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    if (mes < 1 || mes > 12) {
      return '';
    }

    return meses[mes - 1];
  }
}

class _PortadaFallback extends StatelessWidget {
  final Color color;

  const _PortadaFallback({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.10),
      alignment: Alignment.center,
      child: Icon(Icons.menu_book_rounded, color: color, size: 24),
    );
  }
}
