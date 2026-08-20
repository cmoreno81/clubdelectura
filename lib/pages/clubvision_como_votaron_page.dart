import 'package:flutter/material.dart';

import '../models/como_votaron.dart';
import '../navigation/book_detail_navigation.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/awarded_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

class ClubvisionComoVotaronPage extends StatefulWidget {
  const ClubvisionComoVotaronPage({super.key});

  @override
  State<ClubvisionComoVotaronPage> createState() =>
      _ClubvisionComoVotaronPageState();
}

class _ClubvisionComoVotaronPageState extends State<ClubvisionComoVotaronPage> {
  late Future<List<ComoVotaron>> future;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    future = ApiService().getComoVotaron();
  }

  Future<void> _refrescar() async {
    setState(_recargar);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cómo votaron')),
      body: FutureBuilder<List<ComoVotaron>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CardListSkeleton();
          }

          if (snapshot.hasError) {
            return ErrorView(
              onRetry: () {
                setState(_recargar);
              },
            );
          }

          final lista = snapshot.data ?? const <ComoVotaron>[];

          if (lista.isEmpty) {
            return _VotacionesVacias(onRefresh: _refrescar);
          }

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                110,
              ),
              children: [
                _ComoVotaronHeader(totalLectoras: lista.length),

                const SizedBox(height: AppSpacing.lg),

                const _SectionHeader(
                  icon: Icons.groups_2_outlined,
                  color: AppColors.primary,
                  title: 'Las papeletas del club',
                  subtitle: 'Así repartió sus puntos cada miembro',
                ),

                const SizedBox(height: AppSpacing.md),

                for (var index = 0; index < lista.length; index++) ...[
                  _VotanteCard(persona: lista[index]),

                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ComoVotaronHeader extends StatelessWidget {
  final int totalLectoras;

  const _ComoVotaronHeader({required this.totalLectoras});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFF1E8FF)],
      ),
      borderColor: AppColors.primaryLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.ballot_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Así votó el club',
                  style: AppTextStyles.section.copyWith(fontSize: 21),
                ),
                const SizedBox(height: 2),
                Text(
                  totalLectoras == 1
                      ? 'Una persona dejó registrada su clasificación.'
                      : '$totalLectoras personas dejaron registrada su clasificación.',
                  style: AppTextStyles.bodySecondary.copyWith(height: 1.3),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClubChip(
                  label: totalLectoras == 1
                      ? '1 papeleta'
                      : '$totalLectoras papeletas',
                  icon: Icons.how_to_vote_outlined,
                  variant: ClubChipVariant.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: color, size: 27),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.section.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                subtitle,
                style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VotanteCard extends StatefulWidget {
  final ComoVotaron persona;

  const _VotanteCard({required this.persona});

  @override
  State<_VotanteCard> createState() => _VotanteCardState();
}

class _VotanteCardState extends State<_VotanteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: EdgeInsets.zero,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera táctil ──────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  ClubAvatar(
                    nombre: widget.persona.usuaria,
                    imageUrl: widget.persona.avatarUrl,
                    size: 56,
                  ),

                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.persona.usuaria,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.section.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        Text(
                          widget.persona.votos.length == 1
                              ? '1 libro clasificado'
                              : '${widget.persona.votos.length} libros clasificados',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  const ClubChip(
                    label: 'Papeleta',
                    icon: Icons.ballot_outlined,
                    variant: ClubChipVariant.primary,
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Chevron animado
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Votos (expandibles animados) ─────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.md),
                        for (var i = 0;
                            i < widget.persona.votos.length;
                            i++) ...[
                          _VotoEmitidoRow(
                            posicion: i,
                            voto: widget.persona.votos[i],
                          ),
                          if (i < widget.persona.votos.length - 1)
                            const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _VotoEmitidoRow extends StatelessWidget {
  final int posicion;
  final VotoEmitido voto;

  const _VotoEmitidoRow({required this.posicion, required this.voto});

  @override
  Widget build(BuildContext context) {
    final color = switch (posicion) {
      0 => const Color(0xFFE4B63F),
      1 => const Color(0xFF9AA3AF),
      2 => const Color(0xFFB77948),
      _ => AppColors.primary,
    };

    final icono = switch (posicion) {
      0 => Icons.emoji_events_rounded,
      1 => Icons.workspace_premium_rounded,
      2 => Icons.workspace_premium_outlined,
      _ => null,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AwardedBookCover(
            title: voto.libro,
            imageUrl: voto.coverUrl,
            position: posicion + 1,
            width: 54,
            height: 78,
            onTap: () => openBookDetail(
              context,
              title: voto.libro,
              bookId: voto.bookId,
              coverUrl: voto.coverUrl,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voto.libro,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Row(
                  children: [
                    if (icono != null) ...[
                      Icon(icono, color: color, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Text(
                      '${posicion + 1}.ª posición',
                      style: AppTextStyles.caption.copyWith(color: color),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          ClubChip(
            label: '${voto.puntos} pt',
            icon: Icons.star_outline_rounded,
            variant: posicion == 0
                ? ClubChipVariant.warning
                : ClubChipVariant.primary,
          ),
        ],
      ),
    );
  }
}

class _VotacionesVacias extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _VotacionesVacias({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.68,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.ballot_outlined,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Todavía no hay papeletas',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.section,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Cuando los miembros voten, sus clasificaciones aparecerán aquí.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
