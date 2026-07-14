import 'package:flutter/material.dart';

import '../../models/capitulo_lectura.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_card.dart';
import '../ui/club_metric.dart';
import 'fecha_relativa.dart';

class CapituloTile extends StatelessWidget {
  final CapituloLectura capitulo;

  /// Indica si el contenido secundario está oculto.
  final bool plegado;

  /// Abre la conversación del capítulo.
  final VoidCallback onTap;

  /// Pliega o despliega solamente esta tarjeta.
  final VoidCallback onTogglePlegado;

  const CapituloTile({
    super.key,
    required this.capitulo,
    required this.plegado,
    required this.onTap,
    required this.onTogglePlegado,
  });

  @override
  Widget build(BuildContext context) {
    final tieneActividad = capitulo.ultimaActividad.trim().isNotEmpty;

    final tieneNovedades = capitulo.tieneNovedades && capitulo.nuevosTotal > 0;

    final colorPrincipal = Theme.of(context).colorScheme.primary;

    return ClubCard(
      elevated: tieneNovedades,
      padding: EdgeInsets.zero,
      backgroundColor: tieneNovedades
          ? colorPrincipal.withOpacity(0.045)
          : AppColors.surface,
      borderColor: tieneNovedades
          ? colorPrincipal.withOpacity(0.36)
          : AppColors.border,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CabeceraCapitulo(
              capitulo: capitulo,
              plegado: plegado,
              tieneNovedades: tieneNovedades,
              colorPrincipal: colorPrincipal,
              onTogglePlegado: onTogglePlegado,
            ),

            if (!plegado)
              _ContenidoCapitulo(
                capitulo: capitulo,
                tieneActividad: tieneActividad,
                tieneNovedades: tieneNovedades,
                colorPrincipal: colorPrincipal,
                onTap: onTap,
              ),
          ],
        ),
      ),
    );
  }
}

class _CabeceraCapitulo extends StatelessWidget {
  final CapituloLectura capitulo;
  final bool plegado;
  final bool tieneNovedades;
  final Color colorPrincipal;
  final VoidCallback onTogglePlegado;

  const _CabeceraCapitulo({
    required this.capitulo,
    required this.plegado,
    required this.tieneNovedades,
    required this.colorPrincipal,
    required this.onTogglePlegado,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(AppRadius.lg),
        bottom: plegado ? const Radius.circular(AppRadius.lg) : Radius.zero,
      ),
      onTap: onTogglePlegado,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChapterIcon(tieneNovedades: tieneNovedades, color: colorPrincipal),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capitulo.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  if (tieneNovedades) ...[
                    const SizedBox(height: AppSpacing.sm),

                    _NovedadesBadge(
                      total: capitulo.nuevosTotal,
                      color: colorPrincipal,
                    ),
                  ] else if (plegado && capitulo.comentarios > 0) ...[
                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      _resumenCapitulo(capitulo),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            AnimatedRotation(
              turns: plegado ? 0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tieneNovedades
                      ? colorPrincipal.withOpacity(0.12)
                      : AppColors.surfaceSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: tieneNovedades ? colorPrincipal : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resumenCapitulo(CapituloLectura capitulo) {
    final partes = <String>[
      '${capitulo.comentarios} '
          '${capitulo.comentarios == 1 ? 'comentario' : 'comentarios'}',
    ];

    if (capitulo.respuestas > 0) {
      partes.add(
        '${capitulo.respuestas} '
        '${capitulo.respuestas == 1 ? 'respuesta' : 'respuestas'}',
      );
    }

    return partes.join(' · ');
  }
}

class _ContenidoCapitulo extends StatelessWidget {
  final CapituloLectura capitulo;
  final bool tieneActividad;
  final bool tieneNovedades;
  final Color colorPrincipal;
  final VoidCallback onTap;

  const _ContenidoCapitulo({
    required this.capitulo,
    required this.tieneActividad,
    required this.tieneNovedades,
    required this.colorPrincipal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ClubMetric(
                icon: Icons.chat_bubble_outline_rounded,
                value: '${capitulo.comentarios}',
                label: capitulo.comentarios == 1 ? 'comentario' : 'comentarios',
                variant: ClubMetricVariant.primary,
                compact: true,
              ),

              ClubMetric(
                icon: Icons.favorite_border_rounded,
                value: '${capitulo.likes}',
                label: capitulo.likes == 1 ? 'reacción' : 'reacciones',
                variant: ClubMetricVariant.danger,
                compact: true,
              ),

              ClubMetric(
                icon: Icons.reply_rounded,
                value: '${capitulo.respuestas}',
                label: capitulo.respuestas == 1 ? 'respuesta' : 'respuestas',
                variant: ClubMetricVariant.primary,
                compact: true,
              ),
            ],
          ),

          if (tieneActividad) ...[
            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: tieneNovedades
                    ? Colors.white.withOpacity(0.72)
                    : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 17,
                    color: tieneNovedades
                        ? colorPrincipal
                        : AppColors.textMuted,
                  ),

                  const SizedBox(width: AppSpacing.xs),

                  Expanded(
                    child: Text(
                      FechaRelativa.formato(capitulo.ultimaActividad),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        height: 1.3,
                        color: tieneNovedades ? AppColors.textSecondary : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    tieneNovedades
                        ? Icons.mark_chat_unread_outlined
                        : Icons.auto_stories_outlined,
                    size: 18,
                    color: tieneNovedades ? colorPrincipal : AppColors.primary,
                  ),

                  const SizedBox(width: AppSpacing.xs),

                  Expanded(
                    child: Text(
                      tieneNovedades
                          ? 'Ver novedades'
                          : 'Entrar en el capítulo',
                      style: AppTextStyles.body.copyWith(
                        color: tieneNovedades
                            ? colorPrincipal
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Icon(
                    Icons.chevron_right_rounded,
                    color: tieneNovedades ? colorPrincipal : AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterIcon extends StatelessWidget {
  final bool tieneNovedades;
  final Color color;

  const _ChapterIcon({required this.tieneNovedades, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: tieneNovedades
                ? color.withOpacity(0.14)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(
            tieneNovedades
                ? Icons.mark_chat_unread_outlined
                : Icons.forum_outlined,
            color: tieneNovedades ? color : AppColors.primary,
            size: 25,
          ),
        ),

        if (tieneNovedades)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _NovedadesBadge extends StatelessWidget {
  final int total;
  final Color color;

  const _NovedadesBadge({required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record_rounded, size: 10, color: color),

          const SizedBox(width: 5),

          Text(
            total == 1 ? '1 nuevo' : '$total nuevos',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
