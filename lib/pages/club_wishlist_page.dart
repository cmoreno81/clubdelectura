import 'package:flutter/material.dart';

import '../models/wishlist.dart';
import '../services/wishlist_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_shimmer.dart';
import '../widgets/common/optimized_network_image.dart';
import '../widgets/error_view.dart';
import 'wishlist_page.dart';

// ─── Helpers de formato ────────────────────────────────────────────────────────

const _shortMonths = [
  '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String _fmtDate(DateTime d) {
  final now = DateTime.now();
  if (d.year == now.year) return '${d.day} ${_shortMonths[d.month]}';
  return '${d.day} ${_shortMonths[d.month]} ${d.year}';
}

// ─── Página ────────────────────────────────────────────────────────────────────

class ClubWishlistPage extends StatefulWidget {
  const ClubWishlistPage({super.key});

  @override
  State<ClubWishlistPage> createState() => _ClubWishlistPageState();
}

class _ClubWishlistPageState extends State<ClubWishlistPage> {
  final _service = WishlistService();
  late Future<ClubWishlistData> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getClubWishlist();
  }

  void _reload() => setState(() => _future = _service.getClubWishlist());

  Future<void> _addToMyList(ClubWishlistGroup group) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WishlistAddSheet(
        prefill: WishlistPrefill(
          title: group.title,
          author: group.author,
          coverUrl: group.coverUrl,
          releaseDate: group.releaseDate,
        ),
      ),
    );
    if (added == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lo que quiere el club'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<ClubWishlistData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _Skeleton();
          }
          if (snap.hasError || snap.data == null) {
            return ErrorView(onRetry: _reload);
          }

          final data = snap.data!;

          if (data.items.isEmpty) {
            return _EmptyState(clubName: data.clubName);
          }

          return CustomScrollView(
            slivers: [
              // ── Cabecera-resumen ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _Header(data: data),
              ),

              // ── Lista de libros ───────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl,
                ),
                sliver: SliverList.separated(
                  itemCount: data.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _BookTile(
                    group: data.items[i],
                    onAdd: data.items[i].isInMyWishlist
                        ? null
                        : () => _addToMyList(data.items[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Cabecera ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.data});
  final ClubWishlistData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B4E92), Color(0xFF40254F)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🛍️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lista del club',
                      style: AppTextStyles.section.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      data.clubName,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: .75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _Pill('${data.membersWithWishlist} miembro${data.membersWithWishlist != 1 ? 's' : ''}'),
              const SizedBox(width: AppSpacing.xs),
              _Pill('${data.totalItems} libro${data.totalItems != 1 ? 's' : ''}'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Libros que las miembros queréis comprar. Toca cualquiera para añadirlo a tu propia lista.',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: .70),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Tile de libro del club ────────────────────────────────────────────────────

class _BookTile extends StatelessWidget {
  const _BookTile({required this.group, required this.onAdd});
  final ClubWishlistGroup group;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = group.isUpcoming && group.releaseDate != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isUpcoming
              ? AppColors.primary.withValues(alpha: .25)
              : AppColors.paperLine,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Portada ─────────────────────────────────────────────────────
            _Cover(coverUrl: group.coverUrl, title: group.title),
            const SizedBox(width: AppSpacing.sm),

            // ── Contenido ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    group.title,
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Autora
                  if (group.author != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      group.author!,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),

                  // Chips: novedad + quién la quiere
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (isUpcoming)
                        _Chip(
                          label: '🗓 Sale ${_fmtDate(group.releaseDate!)}',
                          color: AppColors.primary,
                          bg: AppColors.primaryLight,
                        ),
                      ..._memberChips(group.members),
                    ],
                  ),

                  if (onAdd != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded, size: 14),
                        label: const Text('Añadir a mi lista'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: .5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _memberChips(List<ClubWishlistMember> members) {
    return members.map((m) {
      return _Chip(
        label: m.name.split(' ').first,
        color: AppColors.textSecondary,
        bg: AppColors.surfaceSoft,
      );
    }).toList();
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.coverUrl, required this.title});
  final String? coverUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: OptimizedNetworkImage(
          url: coverUrl!,
          width: 52,
          height: 74,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 52,
      height: 74,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.book_rounded, color: AppColors.primary, size: 24),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.bg});
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.clubName});
  final String clubName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🛍️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nadie ha añadido libros aún',
              style: AppTextStyles.section,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cuando las miembros de $clubName añadan libros a su wishlist, aparecerán aquí.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton ──────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          ClubShimmer(
            width: double.infinity,
            height: 110,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(4, (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ClubShimmer(
              width: double.infinity,
              height: 100,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          )),
        ],
      ),
    );
  }
}
