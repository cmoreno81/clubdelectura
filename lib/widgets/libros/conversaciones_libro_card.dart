import 'package:flutter/material.dart';

import '../../navigation/app_page_route.dart';
import '../../models/conversacion_libro.dart';
import '../../pages/lectura_page.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_card.dart';
import '../common/club_chip.dart';
import '../ui/club_metric.dart';
import 'libro_section.dart';

class ConversacionesLibroCard extends StatelessWidget {
  final String libro;
  final String coverUrl;

  const ConversacionesLibroCard({
    super.key,
    required this.libro,
    this.coverUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConversacionLibro>>(
      future: ApiService().getConversacionesLibro(libro: libro),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LibroSection(
            icon: Icons.forum_outlined,
            color: AppColors.primary,
            title: 'Conversaciones',
            subtitle: 'Debates y comentarios sobre esta lectura',
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return LibroSection(
            icon: Icons.forum_outlined,
            color: AppColors.primary,
            title: 'Conversaciones',
            subtitle: 'Debates y comentarios sobre esta lectura',
            child: const _ConversacionesError(),
          );
        }

        final conversaciones = snapshot.data ?? const <ConversacionLibro>[];

        if (conversaciones.isEmpty) {
          return const SizedBox.shrink();
        }

        return LibroSection(
          icon: Icons.forum_outlined,
          color: AppColors.primary,
          title: 'Conversaciones',
          subtitle: conversaciones.length == 1
              ? 'Hay una conversación sobre este libro'
              : '${conversaciones.length} espacios para compartir la lectura',
          child: Column(
            children: [
              for (var index = 0; index < conversaciones.length; index++) ...[
                _ConversacionCard(
                  conversacion: conversaciones[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (_) =>
                            LecturaPage(libro: libro, coverUrl: coverUrl),
                      ),
                    );
                  },
                ),

                if (index < conversaciones.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ConversacionCard extends StatelessWidget {
  final ConversacionLibro conversacion;
  final VoidCallback onTap;

  const _ConversacionCard({required this.conversacion, required this.onTap});

  bool get esOficial {
    return conversacion.tipo.trim().toUpperCase() == 'OFICIAL';
  }

  bool get estaActiva {
    return conversacion.estado.trim().toUpperCase() == 'ACTIVA';
  }

  @override
  Widget build(BuildContext context) {
    final colorPrincipal = esOficial ? AppColors.primary : AppColors.info;

    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: esOficial
          ? AppColors.surfaceSoft
          : const Color(0xFFF3F7FD),
      borderColor: colorPrincipal.withValues(alpha: 0.20),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorPrincipal.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  esOficial
                      ? Icons.emoji_events_outlined
                      : Icons.groups_2_outlined,
                  color: colorPrincipal,
                  size: 27,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Text(
                  esOficial ? 'Lectura oficial' : 'Lectura compartida',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: colorPrincipal,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Align(
            alignment: Alignment.centerLeft,
            child: ClubChip(
              label: estaActiva
                  ? 'Conversación activa'
                  : 'Conversación cerrada',
              icon: estaActiva
                  ? Icons.radio_button_checked_rounded
                  : Icons.lock_outline_rounded,
              variant: estaActiva
                  ? ClubChipVariant.success
                  : ClubChipVariant.neutral,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ClubMetric(
                icon: Icons.chat_bubble_outline_rounded,
                value: '${conversacion.comentarios}',
                label: conversacion.comentarios == 1
                    ? 'comentario'
                    : 'comentarios',
                variant: ClubMetricVariant.primary,
                compact: true,
              ),

              ClubMetric(
                icon: Icons.favorite_border_rounded,
                value: '${conversacion.likes}',
                label: conversacion.likes == 1 ? 'reacción' : 'reacciones',
                variant: ClubMetricVariant.danger,
                compact: true,
              ),
            ],
          ),

          if (conversacion.ultimaActividad.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 17,
                    color: AppColors.textMuted,
                  ),

                  const SizedBox(width: AppSpacing.xs),

                  Expanded(
                    child: Text(
                      conversacion.ultimaActividad,
                      style: AppTextStyles.caption.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 18,
                color: colorPrincipal,
              ),

              const SizedBox(width: AppSpacing.xs),

              Expanded(
                child: Text(
                  estaActiva
                      ? 'Entrar en la conversación'
                      : 'Consultar la conversación',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: colorPrincipal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              Icon(Icons.chevron_right_rounded, color: colorPrincipal),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConversacionesError extends StatelessWidget {
  const _ConversacionesError();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.textMuted,
            size: 34,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'No hemos podido cargar las conversaciones.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
