import 'package:flutter/material.dart';

import '../models/historial_clubvision.dart';
import '../navigation/book_detail_navigation.dart';
import '../services/api_service.dart';
import '../services/cursor_pagination_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/common/awarded_book_cover.dart';
import '../widgets/error_view.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

class ClubvisionHistorialPage extends StatefulWidget {
  const ClubvisionHistorialPage({super.key});

  @override
  State<ClubvisionHistorialPage> createState() =>
      _ClubvisionHistorialPageState();
}

class _ClubvisionHistorialPageState extends State<ClubvisionHistorialPage> {
  late final CursorPaginationController<HistorialClubvision> _pagination;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pagination = CursorPaginationController(
      loadPage: (cursor) =>
          ApiService().getHistorialClubvisionPage(cursor: cursor),
      keyOf: (item) => item.mes,
    )..loadFirst();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 500) {
      _pagination.loadMore();
    }
  }

  Future<void> _refrescar() => _pagination.loadFirst();

  @override
  void dispose() {
    _scrollController.dispose();
    _pagination.dispose();
    super.dispose();
  }

  String _mes(String fecha) {
    try {
      final partes = fecha.split('-');

      final anio = int.parse(partes[0]);
      final mes = int.parse(partes[1]);

      const meses = [
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

      return '${meses[mes - 1]} $anio';
    } catch (_) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: AnimatedBuilder(
        animation: _pagination,
        builder: (context, _) {
          if (_pagination.showInitialLoader) {
            return const CardListSkeleton();
          }

          if (_pagination.showInitialError) {
            return ErrorView(onRetry: _pagination.loadFirst);
          }

          final historial = _pagination.items;

          if (_pagination.showEmpty) {
            return _HistorialVacio(onRefresh: _refrescar);
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refrescar,
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    110,
                  ),
                  children: [
                    _HistorialHeader(
                      totalEdiciones: _pagination.hasMore
                          ? null
                          : historial.length,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const _SectionHeader(
                      icon: Icons.history_rounded,
                      color: AppColors.primary,
                      title: 'Ediciones anteriores',
                      subtitle: 'Las historias que fueron elegidas por el club',
                    ),

                    const SizedBox(height: AppSpacing.md),

                    for (var index = 0; index < historial.length; index++) ...[
                      _EdicionCard(
                        historial: historial[index],
                        mes: _mes(historial[index].mes),
                        destacada: index == 0,
                      ),

                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (_pagination.loadingMore)
                      const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (_pagination.loadMoreError != null)
                      Center(
                        child: TextButton.icon(
                          onPressed: _pagination.loadMore,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text(
                            'No se pudo cargar más. Reintentar',
                          ),
                        ),
                      ),
                    if (_pagination.hasContentError)
                      Center(
                        child: TextButton.icon(
                          onPressed: _pagination.loadFirst,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text(
                            'No se pudo actualizar. Reintentar',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_pagination.refreshing)
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HistorialHeader extends StatelessWidget {
  final int? totalEdiciones;

  const _HistorialHeader({required this.totalEdiciones});

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
              Icons.auto_stories_rounded,
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
                  'La historia de Clubvisión',
                  style: AppTextStyles.section.copyWith(fontSize: 21),
                ),
                const SizedBox(height: 2),
                Text(
                  totalEdiciones == null
                      ? 'Las ediciones que forman parte de la historia del club.'
                      : totalEdiciones == 1
                      ? 'Una edición forma parte de la historia del club.'
                      : '$totalEdiciones ediciones forman parte de la historia del club.',
                  style: AppTextStyles.bodySecondary.copyWith(height: 1.3),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClubChip(
                  label: totalEdiciones == 1
                      ? '1 ganadora'
                      : totalEdiciones == null
                      ? 'Ganadoras'
                      : '$totalEdiciones ganadoras',
                  icon: Icons.emoji_events_outlined,
                  variant: ClubChipVariant.warning,
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

class _EdicionCard extends StatelessWidget {
  final HistorialClubvision historial;
  final String mes;
  final bool destacada;

  const _EdicionCard({
    required this.historial,
    required this.mes,
    required this.destacada,
  });

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: destacada,
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: destacada
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFBF0), Color(0xFFFFF4D8)],
            )
          : null,
      backgroundColor: destacada ? null : AppColors.surface,
      borderColor: destacada ? const Color(0xFFF1E2B3) : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: destacada
                      ? const Color(0xFFFFEDBA)
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  destacada
                      ? Icons.emoji_events_rounded
                      : Icons.calendar_month_rounded,
                  color: destacada
                      ? const Color(0xFFB48113)
                      : AppColors.primary,
                  size: 29,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mes,
                      style: AppTextStyles.section.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      destacada
                          ? 'Última edición celebrada'
                          : 'Edición de Clubvisión',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),

              if (destacada)
                const ClubChip(
                  label: 'Más reciente',
                  icon: Icons.auto_awesome_rounded,
                  variant: ClubChipVariant.warning,
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: destacada ? 0.72 : 1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: const Color(0xFFF1E2B3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AwardedBookCover(
                  title: historial.ganadora,
                  imageUrl: historial.ganadoraCoverUrl,
                  position: 1,
                  width: 78,
                  height: 112,
                  onTap: () => openBookDetail(
                    context,
                    title: historial.ganadora,
                    bookId: historial.ganadoraBookId,
                    coverUrl: historial.ganadoraCoverUrl,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ganadora',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFB48113),
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        historial.ganadora,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.section.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClubChip(
                        label: '${historial.puntos} puntos',
                        icon: Icons.star_outline_rounded,
                        variant: ClubChipVariant.warning,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          _PodioItem(
            posicion: 2,
            libro: historial.segunda,
            bookId: historial.segundaBookId,
            coverUrl: historial.segundaCoverUrl,
          ),

          const SizedBox(height: AppSpacing.sm),

          _PodioItem(
            posicion: 3,
            libro: historial.tercera,
            bookId: historial.terceraBookId,
            coverUrl: historial.terceraCoverUrl,
          ),
        ],
      ),
    );
  }
}

class _PodioItem extends StatelessWidget {
  final int posicion;
  final String libro;
  final String bookId;
  final String coverUrl;

  const _PodioItem({
    required this.posicion,
    required this.libro,
    required this.bookId,
    required this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final esSegunda = posicion == 2;

    final color = esSegunda ? const Color(0xFF9AA3AF) : const Color(0xFFB77948);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          AwardedBookCover(
            title: libro,
            imageUrl: coverUrl,
            position: posicion,
            width: 50,
            height: 72,
            onTap: () => openBookDetail(
              context,
              title: libro,
              bookId: bookId,
              coverUrl: coverUrl,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Text(
              libro.trim().isEmpty ? 'Sin datos' : libro,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorialVacio extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _HistorialVacio({required this.onRefresh});

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
                        Icons.history_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Todavía no hay ediciones anteriores',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.section,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    const Text(
                      'Las futuras ganadoras de Clubvisión aparecerán aquí.',
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
