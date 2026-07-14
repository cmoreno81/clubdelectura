import 'package:flutter/material.dart';

import '../../models/perfil_usuario.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/genero_utils.dart';
import '../../utils/lectura_fecha_utils.dart';
import '../common/club_card.dart';

class PerfilTimelineLectura extends StatelessWidget {
  final List<PerfilLibroTerminado> libros;

  const PerfilTimelineLectura({super.key, required this.libros});

  @override
  Widget build(BuildContext context) {
    final grupos = _agruparPorMes(libros);

    if (grupos.isEmpty) {
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
      children: grupos.entries.map((grupo) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _GrupoMesTimeline(titulo: grupo.key, libros: grupo.value),
        );
      }).toList(),
    );
  }

  Map<String, List<PerfilLibroTerminado>> _agruparPorMes(
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

    final grupos = <String, List<PerfilLibroTerminado>>{};

    for (final item in conFecha) {
      final fecha = item.fecha!;
      final clave = '${_nombreMes(fecha.month)} ${fecha.year}';

      grupos.putIfAbsent(clave, () => []);
      grupos[clave]!.add(item.libro);
    }

    return grupos;
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

class _GrupoMesTimeline extends StatelessWidget {
  final String titulo;
  final List<PerfilLibroTerminado> libros;

  const _GrupoMesTimeline({required this.titulo, required this.libros});

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

  const _TimelineEntrada({required this.libro, required this.esUltima});

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

                        if (libro.valoracion.isNotEmpty) ...[
                          const SizedBox(height: 5),

                          Text(
                            libro.valoracion,
                            style: const TextStyle(fontSize: 13),
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
