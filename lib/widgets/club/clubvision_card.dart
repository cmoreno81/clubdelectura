import 'package:club_lectura_app/pages/clubvision_menu_page.dart';
import 'package:flutter/material.dart';

import '../../navigation/app_page_route.dart';
import '../../models/dashboard.dart';
import '../../models/estado_club.dart';
import '../../pages/clubvision_votacion_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_button.dart';
import '../common/club_card.dart';
import '../common/club_chip.dart';
import 'director_escenas.dart';

class ClubvisionCard extends StatelessWidget {
  final Dashboard dashboard;
  final EstadoClub estadoClub;
  final bool haVotado;
  final Future<void> Function() onActualizar;

  const ClubvisionCard({
    super.key,
    required this.dashboard,
    required this.estadoClub,
    required this.haVotado,
    required this.onActualizar,
  });

  bool get _mostrarFlecha {
    final estado = dashboard.clubvision.estado.toUpperCase();

    return estado == 'LECTURA' ||
        estado == 'VOTACION' ||
        estado == 'RESULTADOS';
  }

  Future<void> _abrirClubvision(BuildContext context) async {
    await Navigator.push(
      context,
      AppPageRoute(builder: (_) => const ClubvisionMenuPage()),
    );

    await onActualizar();
  }

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      padding: EdgeInsets.zero,
      borderColor: estadoClub.iconColor.withValues(alpha: 0.18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          estadoClub.color,
          Color.lerp(estadoClub.color, AppColors.surface, 0.55) ??
              estadoClub.color,
        ],
      ),
      onTap: () => _abrirClubvision(context),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _cabecera(),

                const SizedBox(height: AppSpacing.lg),

                DirectorEscenas().construir(
                  estado: estadoClub,
                  dashboard: dashboard,
                ),

                if (estadoClub.permiteVotar) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _bloqueVotacion(context),
                ],

                if (estadoClub.mostrarGanador) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _bloqueGanador(),
                ],
              ],
            ),
          ),

          if (_mostrarFlecha)
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cabecera() {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Icon(estadoClub.icono, size: 34, color: estadoClub.iconColor),
        ),

        const SizedBox(height: AppSpacing.md),

        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _mostrarFlecha ? AppSpacing.xl : 0,
          ),
          child: Text(
            estadoClub.titulo,
            textAlign: TextAlign.center,
            style: AppTextStyles.section.copyWith(fontWeight: FontWeight.w700),
          ),
        ),

        if (estadoClub.mensaje.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),

          Text(
            estadoClub.mensaje,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ],
    );
  }

  Widget _bloqueVotacion(BuildContext context) {
    final total = dashboard.clubvision.totalUsuarios;
    final recibidos = dashboard.clubvision.votosRecibidos;

    final progreso = total == 0 ? 0.0 : recibidos / total;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progreso.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.7),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ClubChip(
              label: '$recibidos votos',
              icon: Icons.how_to_vote_outlined,
              variant: ClubChipVariant.primary,
            ),
            ClubChip(
              label: '${dashboard.clubvision.votosPendientes} pendientes',
              icon: Icons.schedule_rounded,
              variant: ClubChipVariant.warning,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        if (!haVotado)
          ClubButton(
            label: 'Votar ahora',
            icon: Icons.how_to_vote_rounded,
            onPressed: () async {
              final actualizado = await Navigator.push<bool>(
                context,
                AppPageRoute(
                  builder: (_) => ClubvisionVotacionPage(
                    idVotacion: dashboard.clubvision.idVotacion,
                  ),
                ),
              );

              if (actualizado == true) {
                await onActualizar();
              }
            },
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 34,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Tu voto ya forma parte de esta historia',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Ahora solo queda esperar al desenlace.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _bloqueGanador() {
    return Column(
      children: [
        if (dashboard.clubvision.estado == 'LECTURA' &&
            dashboard.clubvision.comentarios > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ClubChip(
                      label: '${dashboard.clubvision.comentarios} comentarios',
                      icon: Icons.chat_bubble_outline_rounded,
                      variant: ClubChipVariant.primary,
                    ),
                    ClubChip(
                      label: '${dashboard.clubvision.likes}',
                      icon: Icons.favorite_border_rounded,
                      variant: ClubChipVariant.danger,
                    ),
                  ],
                ),

                if (dashboard.clubvision.ultimaActividad.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    dashboard.clubvision.ultimaActividad,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),
        ],

        ClubChip(
          label: dashboard.clubvision.lectoras.isEmpty
              ? 'Estreno para todo el club'
              : 'Ya leído por ${dashboard.clubvision.lectoras.length}',
          icon: dashboard.clubvision.lectoras.isEmpty
              ? Icons.auto_awesome_rounded
              : Icons.star_outline_rounded,
          variant: ClubChipVariant.warning,
        ),

        if (dashboard.clubvision.lectoras.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),

          Text(
            dashboard.clubvision.lectoras.join(' · '),
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }
}
