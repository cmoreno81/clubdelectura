import 'package:flutter/material.dart';

import '../models/ranking.dart';
import '../models/ranking_item.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';

class RankingPage extends StatefulWidget {
  final int initialTab;

  const RankingPage({super.key, this.initialTab = 0});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  late Future<Ranking> rankingFuture;

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _topLectorasKey = GlobalKey();
  final GlobalKey _mejorValoradosKey = GlobalKey();
  final GlobalKey _masLeidosKey = GlobalKey();

  bool _yaHizoScrollInicial = false;

  @override
  void initState() {
    super.initState();
    rankingFuture = ApiService().getRanking();
  }

  void _recargar() {
    rankingFuture = ApiService().getRanking();
  }

  Future<void> _refrescar() async {
    setState(() {
      _yaHizoScrollInicial = false;
      _recargar();
    });

    await rankingFuture;
  }

  void _scrollInicial() {
    if (_yaHizoScrollInicial) return;

    _yaHizoScrollInicial = true;

    GlobalKey? targetKey;

    switch (widget.initialTab) {
      case 1:
        targetKey = _topLectorasKey;
        break;
      case 2:
        targetKey = _mejorValoradosKey;
        break;
      case 3:
        targetKey = _masLeidosKey;
        break;
      default:
        return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = targetKey?.currentContext;

      if (targetContext == null) return;

      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: FutureBuilder<Ranking>(
        future: rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorView(
              onRetry: () {
                setState(() {
                  _yaHizoScrollInicial = false;
                  _recargar();
                });
              },
            );
          }

          final ranking = snapshot.data!;

          _scrollInicial();

          final libroClub = ranking.mejorValorados.isNotEmpty
              ? ranking.mejorValorados.first
              : null;

          final cementerio = ranking.masAbandonados.isNotEmpty
              ? ranking.masAbandonados.first
              : null;

          return RefreshIndicator(
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
                _RankingHeader(anio: ranking.anio),

                const SizedBox(height: AppSpacing.xl),

                KeyedSubtree(
                  key: _topLectorasKey,
                  child: _PodioHistorico(
                    items: ranking.topLectoras.take(4).toList(growable: false),
                  ),
                ),

                if (libroClub != null || cementerio != null) ...[
                  const SizedBox(height: AppSpacing.xl),

                  _SectionHeader(
                    icon: Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    title: 'Lo más destacado',
                    subtitle: 'Las protagonistas de ${ranking.anio}',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  if (libroClub != null) _LibroClubCard(item: libroClub),

                  if (libroClub != null && cementerio != null)
                    const SizedBox(height: AppSpacing.md),

                  if (cementerio != null) _CementerioCard(item: cementerio),
                ],

                const SizedBox(height: AppSpacing.xl),

                _RankingSection(
                  icon: Icons.bookmark_outline_rounded,
                  color: const Color(0xFFB48113),
                  title: 'Más deseados',
                  subtitle: 'Los libros que más esperan las lectoras',
                  items: ranking.masDeseados,
                  valueBuilder: (item) => '${item.total}',
                  unitBuilder: (item) => item.total == 1
                      ? 'lectora interesada'
                      : 'lectoras interesadas',
                ),

                const SizedBox(height: AppSpacing.xl),

                KeyedSubtree(
                  key: _masLeidosKey,
                  child: _RankingSection(
                    icon: Icons.auto_stories_outlined,
                    color: AppColors.info,
                    title: 'Más leídos',
                    subtitle:
                        'Las historias con más lectoras en ${ranking.anio}',
                    items: ranking.masLeidos,
                    valueBuilder: (item) => '${item.total}',
                    unitBuilder: (item) =>
                        item.total == 1 ? 'lectura' : 'lecturas',
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                KeyedSubtree(
                  key: _mejorValoradosKey,
                  child: _RankingSection(
                    icon: Icons.star_outline_rounded,
                    color: const Color(0xFFB48113),
                    title: 'Mejor valorados',
                    subtitle: 'Los favoritos del club en ${ranking.anio}',
                    items: ranking.mejorValorados,
                    valueBuilder: (item) =>
                        '${item.media.toStringAsFixed(2)} / 5',
                    unitBuilder: (item) => item.votos == 1
                        ? '1 valoración'
                        : '${item.votos} valoraciones',
                    showStars: true,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                _RankingSection(
                  icon: Icons.heart_broken_outlined,
                  color: AppColors.danger,
                  title: 'Más abandonados',
                  subtitle: 'Los abandonos registrados en ${ranking.anio}',
                  items: ranking.masAbandonados,
                  valueBuilder: (item) => '${item.total}',
                  unitBuilder: (item) =>
                      item.total == 1 ? 'abandono' : 'abandonos',
                ),

                const SizedBox(height: AppSpacing.xl),

                _RankingSection(
                  icon: Icons.groups_rounded,
                  color: AppColors.primary,
                  title: 'Clasificación de lectoras',
                  subtitle: 'Libros finalizados durante ${ranking.anio}',
                  items: ranking.topLectoras,
                  valueBuilder: (item) => '${item.total}',
                  unitBuilder: (item) => item.total == 1
                      ? 'libro finalizado'
                      : 'libros finalizados',
                  useAvatar: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _RankingHeader extends StatelessWidget {
  final int anio;

  const _RankingHeader({required this.anio});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFF1E8FF)],
      ),
      borderColor: AppColors.primaryLight,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.primary,
              size: 37,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'El ranking del club',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 29),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Lo más leído, valorado y comentado por el club durante $anio.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.45),
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

class _LibroClubCard extends StatelessWidget {
  final RankingItem item;

  const _LibroClubCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: const Color(0xFFFFFBF0),
      borderColor: const Color(0xFFF1E2B3),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDBA),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFFB48113),
              size: 32,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ClubChip(
                  label: 'Libro del club',
                  icon: Icons.auto_awesome_rounded,
                  variant: ClubChipVariant.warning,
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  item.nombre,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  '${item.media.toStringAsFixed(2)} / 5 · '
                  '${item.votos} ${item.votos == 1 ? 'valoración' : 'valoraciones'}',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CementerioCard extends StatelessWidget {
  final RankingItem item;

  const _CementerioCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: const Color(0xFFFFF4F4),
      borderColor: const Color(0xFFF5CECE),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFFDDDD),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.heart_broken_rounded,
              color: AppColors.danger,
              size: 31,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ClubChip(
                  label: 'Cementerio literario',
                  icon: Icons.sentiment_dissatisfied_outlined,
                  variant: ClubChipVariant.danger,
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  item.nombre,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  item.total == 1 ? '1 abandono' : '${item.total} abandonos',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodioHistorico extends StatelessWidget {
  final List<RankingItem> items;

  const _PodioHistorico({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.military_tech_rounded,
          color: Color(0xFF8B6FC2),
          title: 'Salón de honor',
          subtitle: 'Las tres lectoras con más libros terminados en el club',
        ),

        const SizedBox(height: AppSpacing.md),

        ClubCard(
          elevated: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF21172F), Color(0xFF3A2854)],
          ),
          borderColor: const Color(0xFF705A91),
          child: items.isEmpty
              ? const _PodioHistoricoVacio()
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFE9C96B),
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'RÉCORD HISTÓRICO',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFE9C96B),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFE9C96B),
                          size: 18,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: items.length > 1
                              ? _PodioHistoricoPuesto(
                                  item: items[1],
                                  posicion: 2,
                                  pedestalHeight: 48,
                                  metal: const Color(0xFFB7BEC9),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _PodioHistoricoPuesto(
                            item: items.first,
                            posicion: 1,
                            pedestalHeight: 68,
                            metal: const Color(0xFFE9C96B),
                            ganadora: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: items.length > 2
                              ? _PodioHistoricoPuesto(
                                  item: items[2],
                                  posicion: 3,
                                  pedestalHeight: 38,
                                  metal: const Color(0xFFC58B67),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),

                    if (items.length > 3) ...[
                      const SizedBox(height: AppSpacing.md),
                      _AnimoCuartaPosicion(cuarta: items[3], tercera: items[2]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _AnimoCuartaPosicion extends StatelessWidget {
  final RankingItem cuarta;
  final RankingItem tercera;

  const _AnimoCuartaPosicion({required this.cuarta, required this.tercera});

  @override
  Widget build(BuildContext context) {
    final diferencia = (tercera.total - cuarta.total).clamp(0, 1 << 31);

    final mensaje = diferencia == 0
        ? '¡El podio está al alcance de tu próxima lectura!'
        : diferencia == 1
        ? '¡Solo un libro más y estarás rozando el podio!'
        : 'Estás a $diferencia libros de entrar en el podio. ¡A por ellos!';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF8B6FC2).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Text(
              '4',
              style: AppTextStyles.subtitle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Vamos, ${cuarta.nombre}!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  mensaje,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFFD5CCDF),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFE9C96B),
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _PodioHistoricoPuesto extends StatelessWidget {
  final RankingItem item;
  final int posicion;
  final double pedestalHeight;
  final Color metal;
  final bool ganadora;

  const _PodioHistoricoPuesto({
    required this.item,
    required this.posicion,
    required this.pedestalHeight,
    required this.metal,
    this.ganadora = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Puesto $posicion, ${item.nombre}, ${item.total} libros finalizados',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ganadora)
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFE9C96B),
              size: 27,
            )
          else
            const SizedBox(height: 27),

          const SizedBox(height: AppSpacing.xxs),

          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: metal, width: ganadora ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: metal.withValues(alpha: 0.24),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClubAvatar(
              nombre: item.nombre,
              imageUrl: item.avatarUrl,
              size: ganadora ? 60 : 52,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            item.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: ganadora ? 15 : 14,
            ),
          ),

          const SizedBox(height: AppSpacing.xxs),

          Text(
            '${item.total} ${item.total == 1 ? 'libro' : 'libros'}',
            maxLines: 1,
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFFD5CCDF),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Container(
            width: double.infinity,
            height: pedestalHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: metal.withValues(alpha: 0.16),
              border: Border.all(color: metal.withValues(alpha: 0.72)),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
            ),
            child: Text(
              '$posicion',
              style: AppTextStyles.title.copyWith(
                color: metal,
                fontSize: ganadora ? 29 : 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodioHistoricoVacio extends StatelessWidget {
  const _PodioHistoricoVacio();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.military_tech_outlined,
            color: Color(0xFFD5CCDF),
            size: 34,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'El salón de honor aún está esperando a sus protagonistas.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(
              color: const Color(0xFFD5CCDF),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<RankingItem> items;
  final String Function(RankingItem item) valueBuilder;
  final String Function(RankingItem item) unitBuilder;
  final bool useAvatar;
  final bool showStars;

  const _RankingSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.valueBuilder,
    required this.unitBuilder,
    this.useAvatar = false,
    this.showStars = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: icon,
          color: color,
          title: title,
          subtitle: subtitle,
        ),

        const SizedBox(height: AppSpacing.md),

        ClubCard(
          elevated: false,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: items.isEmpty
              ? const _EmptyRanking()
              : Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _RankingRow(
                        position: index + 1,
                        item: items[index],
                        color: color,
                        value: valueBuilder(items[index]),
                        unit: unitBuilder(items[index]),
                        useAvatar: useAvatar,
                        showStars: showStars,
                      ),

                      if (index < items.length - 1)
                        const Divider(
                          height: 1,
                          indent: AppSpacing.md,
                          endIndent: AppSpacing.md,
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  final int position;
  final RankingItem item;
  final Color color;
  final String value;
  final String unit;
  final bool useAvatar;
  final bool showStars;

  const _RankingRow({
    required this.position,
    required this.item,
    required this.color,
    required this.value,
    required this.unit,
    required this.useAvatar,
    required this.showStars,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _PositionBadge(position: position, color: color),

          const SizedBox(width: AppSpacing.md),

          if (useAvatar) ...[
            ClubAvatar(nombre: item.nombre, imageUrl: item.avatarUrl, size: 46),
            const SizedBox(width: AppSpacing.md),
          ],

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                if (showStars) _CompactStars(value: item.media),

                Text(
                  unit,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.subtitle.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final int position;
  final Color color;

  const _PositionBadge({required this.position, required this.color});

  @override
  Widget build(BuildContext context) {
    final medalColor = switch (position) {
      1 => const Color(0xFFE4B63F),
      2 => const Color(0xFF9AA3AF),
      3 => const Color(0xFFB77948),
      _ => color,
    };

    final icon = switch (position) {
      1 => Icons.emoji_events_rounded,
      2 => Icons.workspace_premium_rounded,
      3 => Icons.workspace_premium_outlined,
      _ => null,
    };

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: medalColor.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, color: medalColor, size: 23)
          : Text(
              '$position',
              style: TextStyle(color: medalColor, fontWeight: FontWeight.w800),
            ),
    );
  }
}

class _CompactStars extends StatelessWidget {
  final double value;

  const _CompactStars({required this.value});

  @override
  Widget build(BuildContext context) {
    final filled = value.round().clamp(0, 5);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (index) => Icon(
            index < filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: const Color(0xFFB48113),
            size: 17,
          ),
        ),
      ),
    );
  }
}

class _EmptyRanking extends StatelessWidget {
  const _EmptyRanking();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            color: AppColors.textMuted,
            size: 30,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Todavía no hay datos suficientes.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
