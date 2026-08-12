import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../navigation/book_detail_navigation.dart';

import '../models/tendencias_club.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';
import 'perfil_usuario_page.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

class TendenciasClubPage extends StatefulWidget {
  const TendenciasClubPage({super.key});

  @override
  State<TendenciasClubPage> createState() => _TendenciasClubPageState();
}

class _TendenciasClubPageState extends State<TendenciasClubPage> {
  late Future<TendenciasClub> future;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    future = ApiService().getTendenciasClub();
  }

  Future<void> _refrescar() async {
    setState(_recargar);
    await future;
  }

  void _abrirPerfil(String usuario) {
    final nombre = usuario.trim();

    if (nombre.isEmpty) return;

    Navigator.push(
      context,
      AppPageRoute(builder: (_) => PerfilUsuarioPage(usuario: nombre)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tendencias')),
      body: FutureBuilder<TendenciasClub>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CardListSkeleton();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorView(
              onRetry: () {
                setState(_recargar);
              },
            );
          }

          final data = snapshot.data!;

          final maxGenero = _max(data.generos);
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
                _TendenciasHeader(data: data),

                if (data.generos.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    icon: Icons.sell_outlined,
                    color: AppColors.success,
                    title: 'Géneros en tendencia',
                    subtitle: 'Las historias que más están atrapando al club',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  ClubCard(
                    elevated: false,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      children: [
                        _GenreDistribution(items: data.generos),
                        const SizedBox(height: AppSpacing.sm),
                        for (
                          var index = 0;
                          index < data.generos.length;
                          index++
                        ) ...[
                          _GeneroItem(
                            posicion: index,
                            item: data.generos[index],
                            maximo: maxGenero,
                          ),

                          if (index < data.generos.length - 1)
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

                if (data.libros.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    icon: Icons.local_fire_department_outlined,
                    color: Color(0xFFE98325),
                    title: 'Libros que están ardiendo',
                    subtitle: 'Las lecturas que más coinciden entre lectores',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  SizedBox(
                    height: 254,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: data.libros.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) => _LibroTendenciaCard(
                        posicion: index,
                        item: data.libros[index],
                        onTap: () => openBookDetail(
                          context,
                          title: data.libros[index].nombre,
                          bookId: data.libros[index].id,
                          coverUrl: data.libros[index].coverUrl,
                        ),
                      ),
                    ),
                  ),
                ],

                if (data.lectoras.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),

                  const _SectionHeader(
                    icon: Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    title: 'Quién marca tendencia',
                    subtitle: 'Los lectores con más historias entre manos',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  SizedBox(
                    height: 204,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: data.lectoras.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) => _LectoraTendenciaItem(
                        posicion: index,
                        item: data.lectoras[index],
                        maximo: _max(data.lectoras),
                        onTap: () => _abrirPerfil(data.lectoras[index].nombre),
                      ),
                    ),
                  ),
                ],

                if (data.generos.isEmpty &&
                    data.libros.isEmpty &&
                    data.lectoras.isEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const _TendenciasVacias(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  int _max(List<TendenciaItem> items) {
    if (items.isEmpty) return 0;

    return items.map((item) => item.total).reduce((a, b) => a > b ? a : b);
  }
}

class _TendenciasHeader extends StatelessWidget {
  final TendenciasClub data;

  const _TendenciasHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF0FFF4), Color(0xFFEAF7F0)],
      ),
      borderColor: const Color(0xFFCDE8D5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TrendDonut(data: data),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'El pulso del club',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      data.titular.trim().isEmpty
                          ? 'Muchas historias, un mismo momento lector.'
                          : data.titular,
                      style: AppTextStyles.section.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (data.narrador.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .70),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: .15),
                ),
              ),
              child: Text(
                data.narrador,
                style: AppTextStyles.bodySecondary.copyWith(
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          Wrap(
            alignment: WrapAlignment.start,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ClubChip(
                label:
                    '${data.totalLeyendo} ${data.totalLeyendo == 1 ? 'lectura activa' : 'lecturas activas'}',
                icon: Icons.auto_stories_outlined,
                variant: ClubChipVariant.success,
              ),

              if (data.generos.isNotEmpty)
                ClubChip(
                  label:
                      '${data.generos.length} ${data.generos.length == 1 ? 'género' : 'géneros'}',
                  icon: Icons.sell_outlined,
                  variant: ClubChipVariant.info,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

const _trendColors = [
  Color(0xFF6D4590),
  Color(0xFFE56F61),
  Color(0xFFE4A927),
  Color(0xFF58A486),
  Color(0xFF6D8FD6),
];

class _TrendDonut extends StatelessWidget {
  const _TrendDonut({required this.data});

  final TendenciasClub data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 106,
      height: 106,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(106),
            painter: _DonutPainter(
              values: data.generos.map((item) => item.total).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${data.totalLeyendo}',
                style: AppTextStyles.title.copyWith(
                  color: AppColors.primary,
                  fontSize: 27,
                ),
              ),
              Text(
                'leyendo',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.values});

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * .12;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final total = values.fold<int>(0, (sum, value) => sum + value);

    if (total == 0) {
      paint.color = AppColors.border;
      canvas.drawArc(rect.deflate(stroke / 2), 0, math.pi * 2, false, paint);
      return;
    }

    var start = -math.pi / 2;
    const gap = .07;
    for (var index = 0; index < values.length; index++) {
      final sweep = (values[index] / total) * math.pi * 2;
      paint.color = _trendColors[index % _trendColors.length];
      canvas.drawArc(
        rect.deflate(stroke / 2),
        start + gap / 2,
        math.max(0, sweep - gap),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values.join(',') != values.join(',');
  }
}

class _GenreDistribution extends StatelessWidget {
  const _GenreDistribution({required this.items});

  final List<TendenciaItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (sum, item) => sum + item.total);
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mapa de gustos ahora',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 18,
              child: Row(
                children: [
                  for (var index = 0; index < items.length; index++)
                    Expanded(
                      flex: items[index].total,
                      child: ColoredBox(
                        color: _trendColors[index % _trendColors.length],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              for (var index = 0; index < items.length; index++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _trendColors[index % _trendColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${items[index].nombre} ${(items[index].total / total * 100).round()}%',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
            ],
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

class _GeneroItem extends StatelessWidget {
  final int posicion;
  final TendenciaItem item;
  final int maximo;

  const _GeneroItem({
    required this.posicion,
    required this.item,
    required this.maximo,
  });

  @override
  Widget build(BuildContext context) {
    final progreso = maximo == 0 ? 0.0 : item.total / maximo;

    final destacado = posicion == 0;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: destacado
                      ? const Color(0xFFDDF2E4)
                      : AppColors.surfaceSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: destacado
                    ? const Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.success,
                      )
                    : Text(
                        '${posicion + 1}',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombre,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      item.total == 1 ? '1 lector' : '${item.total} lectores',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              Text(
                '${item.total}',
                style: AppTextStyles.section.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: AppColors.success.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibroTendenciaCard extends StatelessWidget {
  final int posicion;
  final TendenciaItem item;
  final VoidCallback onTap;

  const _LibroTendenciaCard({
    required this.posicion,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primero = posicion == 0;
    final color = switch (posicion) {
      0 => const Color(0xFFE4A927),
      1 => const Color(0xFF9AA3AF),
      2 => const Color(0xFFB77948),
      _ => const Color(0xFFE98325),
    };

    return SizedBox(
      width: 154,
      child: ClubCard(
        elevated: primero,
        padding: const EdgeInsets.all(AppSpacing.sm),
        gradient: primero
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF8EC), Color(0xFFFFE9C8)],
              )
            : null,
        backgroundColor: primero ? null : AppColors.surface,
        borderColor: color.withValues(alpha: .35),
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClubBookCover(
                  title: item.nombre,
                  imageUrl: item.coverUrl,
                  width: 94,
                  height: 138,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                Positioned(
                  top: -7,
                  left: -7,
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: .30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      posicion == 0
                          ? Icons.local_fire_department_rounded
                          : posicion < 3
                          ? Icons.workspace_premium_rounded
                          : Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -5,
                  right: -7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '#${posicion + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              item.nombre,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.total == 1 ? '1 lector' : '${item.total} lectores',
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _LectoraTendenciaItem extends StatelessWidget {
  final int posicion;
  final TendenciaItem item;
  final int maximo;
  final VoidCallback onTap;

  const _LectoraTendenciaItem({
    required this.posicion,
    required this.item,
    required this.maximo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (posicion) {
      0 => const Color(0xFFE4B63F),
      1 => const Color(0xFF9AA3AF),
      2 => const Color(0xFFB77948),
      _ => AppColors.primary,
    };

    final progreso = maximo == 0 ? 0.0 : item.total / maximo;

    return SizedBox(
      width: 142,
      child: ClubCard(
        elevated: posicion == 0,
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        borderColor: color.withValues(alpha: .30),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClubAvatar(
                  nombre: item.nombre,
                  imageUrl: item.avatarUrl,
                  size: 70,
                ),
                Positioned(
                  left: -10,
                  top: -6,
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '${posicion + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.total == 1
                  ? '1 lectura activa'
                  : '${item.total} lecturas activas',
              style: AppTextStyles.caption,
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progreso.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: color.withValues(alpha: .12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TendenciasVacias extends StatelessWidget {
  const _TendenciasVacias();

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppColors.surfaceSoft,
      child: Column(
        children: [
          const Icon(
            Icons.query_stats_outlined,
            color: AppColors.textMuted,
            size: 40,
          ),

          SizedBox(height: AppSpacing.md),

          Text(
            'Todavía no hay una tendencia clara',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),

          SizedBox(height: AppSpacing.sm),

          Text(
            'Cuando el club empiece nuevas lecturas, aparecerán aquí los géneros, libros y lectores más activos.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
