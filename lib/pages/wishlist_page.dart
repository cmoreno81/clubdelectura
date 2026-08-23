import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/wishlist.dart';
import '../navigation/app_page_route.dart';
import '../services/api_exception.dart';
import '../services/wishlist_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_shimmer.dart';
import '../widgets/common/optimized_network_image.dart';
import '../widgets/error_view.dart';

// ─── Helpers de formato (sin dependencia intl) ────────────────────────────────

String _fmtPrice(double price) {
  final parts = price.toStringAsFixed(2).split('.');
  final intPart = parts[0];
  final decPart = parts[1];
  // Separador de miles
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
    buf.write(intPart[i]);
  }
  return '${buf.toString()},${decPart}';
}

const _shortMonths = [
  '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String _fmtDateShort(DateTime d, {bool includeYear = false}) {
  final m = _shortMonths[d.month];
  return includeYear ? '${d.day} $m ${d.year}' : '${d.day} $m';
}

String _fmtMonthYear(DateTime d) =>
    '${_shortMonths[d.month]} ${d.year}';

// ─── Página principal ──────────────────────────────────────────────────────────

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final _service = WishlistService();
  late Future<WishlistData> _future;
  _WishlistTab _tab = _WishlistTab.all;

  @override
  void initState() {
    super.initState();
    _future = _service.getWishlist();
  }

  Future<void> _reload() async {
    final f = _service.getWishlist();
    setState(() => _future = f);
    await f;
  }

  Future<void> _openAdd() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WishlistAddSheet(),
    );
    if (added == true) await _reload();
  }

  Future<void> _openEdit(WishlistItem item) async {
    final edited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WishlistAddSheet(editItem: item),
    );
    if (edited == true) await _reload();
  }

  Future<void> _confirmDelete(WishlistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar libro'),
        content: Text('¿Quitar "${item.title}" de tu lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.deleteItem(item.id);
      await _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis adquisiciones'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Añadir'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<WishlistData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _WishlistSkeleton();
          }
          if (snap.hasError) {
            return ErrorView(onRetry: _reload);
          }
          final data = snap.data!;

          if (data.totalItems == 0) {
            return _EmptyWishlist(onAdd: _openAdd);
          }

          final visibleItems = switch (_tab) {
            _WishlistTab.all => data.items,
            _WishlistTab.available => data.available,
            _WishlistTab.upcoming => data.upcoming,
          };

          return RefreshIndicator(
            onRefresh: _reload,
            notificationPredicate: (n) {
              if (n.depth != 0) return false;
              if (n is OverscrollNotification) return n.velocity.abs() < 50.0;
              return true;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Card de presupuesto ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
                    ),
                    child: _BudgetCard(summary: data.summary),
                  ),
                ),

                // ── Tabs ───────────────────────────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabsDelegate(
                    tab: _tab,
                    upcomingCount: data.summary.upcomingCount,
                    availableCount: data.summary.availableCount,
                    onSelected: (t) => setState(() => _tab = t),
                  ),
                ),

                // ── Lista de ítems ─────────────────────────────────────────
                if (visibleItems.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _tab == _WishlistTab.upcoming
                            ? 'No tienes novedades pendientes'
                            : 'No hay libros disponibles en lista',
                        style: AppTextStyles.bodySecondary,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 120,
                    ),
                    sliver: SliverList.separated(
                      itemCount: visibleItems.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _WishlistTile(
                        item: visibleItems[i],
                        onEdit: () => _openEdit(visibleItems[i]),
                        onDelete: () => _confirmDelete(visibleItems[i]),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Tab enum ───────────────────────────────────────────────────────────────────

enum _WishlistTab { all, available, upcoming }

// ─── Budget card ───────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.summary});
  final WishlistSummary summary;

  @override
  Widget build(BuildContext context) {
    final priceStr = _fmtPrice(summary.totalPrice);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4a2d8a), Color(0xFF6c4cc4)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Presupuesto pendiente',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$priceStr €',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${summary.totalItems} ${summary.totalItems == 1 ? 'libro' : 'libros'} en lista',
                      style: AppTextStyles.caption.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              if (summary.thisMonthPrice > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${_fmtPrice(summary.thisMonthPrice)} € este mes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            children: [
              if (summary.physicalCount > 0)
                _pill('📕 ${summary.physicalCount} físico${summary.physicalCount > 1 ? 's' : ''}'),
              if (summary.digitalCount > 0)
                _pill('📱 ${summary.digitalCount} digital${summary.digitalCount > 1 ? 'es' : ''}'),
              if (summary.audiobookCount > 0)
                _pill('🎧 ${summary.audiobookCount} audio'),
              if (summary.upcomingCount > 0)
                _pill('🗓 ${summary.upcomingCount} próximo${summary.upcomingCount > 1 ? 's' : ''}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// ─── Persistent header de tabs ─────────────────────────────────────────────────

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  const _TabsDelegate({
    required this.tab,
    required this.upcomingCount,
    required this.availableCount,
    required this.onSelected,
  });

  final _WishlistTab tab;
  final int upcomingCount;
  final int availableCount;
  final void Function(_WishlistTab) onSelected;

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(_, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _tabBtn('Todos', _WishlistTab.all, null),
                _tabBtn('Disponibles', _WishlistTab.available, availableCount),
                _tabBtn('Próximas', _WishlistTab.upcoming, upcomingCount),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String label, _WishlistTab t, int? count) {
    final selected = tab == t;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 4)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryLight : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabsDelegate old) =>
      tab != old.tab ||
      upcomingCount != old.upcomingCount ||
      availableCount != old.availableCount;
}

// ─── Tile de ítem ──────────────────────────────────────────────────────────────

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final WishlistItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = item.isUpcoming && item.releaseDate != null;
    final priceStr = item.price != null
        ? '${_fmtPrice(item.price!)} €'
        : null;

    return ClubCard(
      elevated: false,
      borderColor: isUpcoming
          ? AppColors.primary.withValues(alpha: .25)
          : AppColors.paperLine,
      gradient: isUpcoming
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryLight.withValues(alpha: .3),
                AppColors.background,
              ],
            )
          : null,
      onTap: onEdit,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          // ── Portada ─────────────────────────────────────────────────────
          _Cover(coverUrl: item.coverUrl, title: item.title),
          const SizedBox(width: AppSpacing.md),

          // ── Info ─────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.author != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.author!,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (isUpcoming)
                      _Chip(
                        label: 'Sale ${_formatDate(item.releaseDate!)}',
                        color: AppColors.primary,
                        bg: AppColors.primaryLight,
                      ),
                    if (priceStr != null)
                      _Chip(label: priceStr, color: const Color(0xFF2e7d32), bg: const Color(0xFFe8f5e9)),
                    _Chip(
                      label: '${item.format.emoji} ${item.format.label}',
                      color: AppColors.textSecondary,
                      bg: AppColors.surfaceSoft,
                    ),
                  ],
                ),
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.note!,
                    style: AppTextStyles.caption.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // ── Controles ────────────────────────────────────────────────────
          Column(
            children: [
              _PriorityDot(priority: item.priority),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year) {
      return _fmtDateShort(d);
    }
    return _fmtMonthYear(d);
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.coverUrl, required this.title});
  final String? coverUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return ClubBookCover(
        title: title,
        imageUrl: coverUrl!,
        width: 44,
        height: 64,
        showShadow: false,
      );
    }
    return Container(
      width: 44,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.book_rounded, color: AppColors.primary, size: 22),
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
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});
  final WishlistPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      WishlistPriority.high => const Color(0xFFe53935),
      WishlistPriority.medium => const Color(0xFFfb8c00),
      WishlistPriority.low => const Color(0xFF43a047),
    };
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🛒', style: TextStyle(fontSize: 52)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tu lista de adquisición está vacía',
              style: AppTextStyles.section,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Añade los libros que quieres comprar, con precio y fecha si es una novedad.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Añadir mi primer libro'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton ──────────────────────────────────────────────────────────────────

class _WishlistSkeleton extends StatelessWidget {
  const _WishlistSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          ClubShimmer(width: double.infinity, height: 110, borderRadius: BorderRadius.circular(AppRadius.xl)),
          const SizedBox(height: AppSpacing.sm),
          ClubShimmer(width: double.infinity, height: 44, borderRadius: BorderRadius.circular(AppRadius.md)),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ClubShimmer(width: double.infinity, height: 84, borderRadius: BorderRadius.circular(AppRadius.lg)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom sheet añadir / editar ──────────────────────────────────────────────

class WishlistAddSheet extends StatefulWidget {
  const WishlistAddSheet({super.key, this.editItem});
  final WishlistItem? editItem;

  @override
  State<WishlistAddSheet> createState() => _WishlistAddSheetState();
}

class _WishlistAddSheetState extends State<WishlistAddSheet> {
  final _service = WishlistService();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  WishlistFormat _format = WishlistFormat.physical;
  WishlistPriority _priority = WishlistPriority.medium;
  DateTime? _releaseDate;
  String? _coverUrl;
  String? _bookId;
  String? _isbn;

  bool _saving = false;
  bool _searching = false;
  List<GoogleBookResult> _searchResults = [];
  Timer? _searchDebounce;

  bool get _isEdit => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.editItem!;
      _titleCtrl.text = e.title;
      _authorCtrl.text = e.author ?? '';
      _priceCtrl.text = e.price != null ? e.price!.toStringAsFixed(2) : '';
      _noteCtrl.text = e.note ?? '';
      _format = e.format;
      _priority = e.priority;
      _releaseDate = e.releaseDate;
      _coverUrl = e.coverUrl;
      _bookId = e.bookId;
      _isbn = e.isbn;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      final results = await _service.searchBooks(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    });
  }

  void _selectGoogleBook(GoogleBookResult book) {
    setState(() {
      _titleCtrl.text = book.title;
      _authorCtrl.text = book.author ?? _authorCtrl.text;
      _coverUrl = book.coverUrl;
      _isbn = book.isbn;
      _bookId = null; // No es del catálogo interno
      if (book.isFutureRelease) {
        _releaseDate = book.releaseDateTime;
      }
      _searchCtrl.clear();
      _searchResults = [];
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es obligatorio.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
      if (_isEdit) {
        await _service.updateItem(
          widget.editItem!.id,
          title: title,
          author: _authorCtrl.text.trim().isEmpty ? null : _authorCtrl.text.trim(),
          coverUrl: _coverUrl,
          isbn: _isbn,
          format: _format,
          priority: _priority,
          price: price,
          clearPrice: price == null,
          releaseDate: _releaseDate,
          clearReleaseDate: _releaseDate == null,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          clearNote: _noteCtrl.text.trim().isEmpty,
        );
      } else {
        await _service.addItem(
          bookId: _bookId,
          title: title,
          author: _authorCtrl.text.trim().isEmpty ? null : _authorCtrl.text.trim(),
          coverUrl: _coverUrl,
          isbn: _isbn,
          format: _format,
          priority: _priority,
          price: price,
          releaseDate: _releaseDate,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  Future<void> _pickReleaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Fecha de salida',
      locale: const Locale('es'),
    );
    if (picked != null) setState(() => _releaseDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      margin: const EdgeInsets.only(top: 40),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.paperLine,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título del sheet
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? 'Editar libro' : 'Añadir a lista',
                    style: AppTextStyles.section,
                  ),
                ),
                if (_saving)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: _save,
                    child: const Text('Guardar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md,
                AppSpacing.md + bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Buscador Google Books ──────────────────────────────
                  if (!_isEdit) ...[
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Busca el libro en Google Books…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.paperLine),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 12, endIndent: 12),
                          itemBuilder: (_, i) {
                            final r = _searchResults[i];
                            return ListTile(
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              leading: r.coverUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: OptimizedNetworkImage(
                                        url: r.coverUrl!,
                                        width: 32,
                                        height: 46,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.book_rounded, size: 28),
                              title: Text(r.title,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                [
                                  if (r.author != null) r.author!,
                                  if (r.publishedDate != null)
                                    r.isFutureRelease
                                        ? '🗓 Sale ${r.publishedDate}'
                                        : r.publishedDate!,
                                ].join(' · '),
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                              ),
                              onTap: () => _selectGoogleBook(r),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // ── Título ─────────────────────────────────────────────
                  _Label('Título *'),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Título del libro',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Autor ──────────────────────────────────────────────
                  _Label('Autor / Autora'),
                  TextField(
                    controller: _authorCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Opcional',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Formato ────────────────────────────────────────────
                  _Label('Formato'),
                  Row(
                    children: WishlistFormat.values.map((f) {
                      final sel = _format == f;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _format = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primaryLight : AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: sel ? AppColors.primary : AppColors.paperLine,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(f.emoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(height: 2),
                                Text(
                                  f.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: sel ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Precio y fecha ─────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Precio (€)'),
                            TextField(
                              controller: _priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                              ],
                              decoration: const InputDecoration(
                                hintText: 'Ej: 18,90',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Fecha de salida'),
                            InkWell(
                              onTap: _pickReleaseDate,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.paperLine),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  color: AppColors.surfaceSoft,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _releaseDate != null
                                            ? _fmtDateShort(_releaseDate!, includeYear: true)
                                            : 'Ya disponible',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _releaseDate != null
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    if (_releaseDate != null)
                                      GestureDetector(
                                        onTap: () => setState(() => _releaseDate = null),
                                        child: const Icon(Icons.close_rounded,
                                            size: 16, color: AppColors.textSecondary),
                                      )
                                    else
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 16, color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Prioridad ──────────────────────────────────────────
                  _Label('Prioridad'),
                  Row(
                    children: WishlistPriority.values.map((p) {
                      final sel = _priority == p;
                      final color = switch (p) {
                        WishlistPriority.high => const Color(0xFFe53935),
                        WishlistPriority.medium => const Color(0xFFfb8c00),
                        WishlistPriority.low => const Color(0xFF43a047),
                      };
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _priority = p),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? color.withValues(alpha: .1)
                                  : AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: sel ? color : AppColors.paperLine,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              '${p.emoji} ${p.label}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? color : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Nota ───────────────────────────────────────────────
                  _Label('Nota personal (opcional)'),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Para la lista de cumple, regalo…',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    textCapitalization: TextCapitalization.sentences,
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.04,
        ),
      ),
    );
  }
}

// ─── Widget compacto para dashboards (acceso rápido) ──────────────────────────

class WishlistSummaryCard extends StatelessWidget {
  const WishlistSummaryCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  final WishlistData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priceStr = _fmtPrice(data.summary.totalPrice);

    // Muestra hasta 3 ítems de vista previa: primero upcoming, luego available
    final preview = [
      ...data.upcoming,
      ...data.available,
    ].take(3).toList();

    return ClubCard(
      elevated: false,
      borderColor: AppColors.primary.withValues(alpha: .2),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryLight.withValues(alpha: .35),
          AppColors.background,
        ],
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera ──────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Quiero comprar',
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const Spacer(),
              Text(
                '$priceStr €',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // ── Preview de libros ─────────────────────────────────────────────
          if (preview.isEmpty)
            Text(
              'Sin libros en lista aún',
              style: AppTextStyles.caption,
            )
          else
            ...preview.map(
              (item) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    if (item.isUpcoming)
                      const Text('🗓', style: TextStyle(fontSize: 12))
                    else
                      const Text('🛒', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.price != null)
                      Text(
                        '${_fmtPrice(item.price!)} €',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF2e7d32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          if (data.totalItems > 3) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '+${data.totalItems - 3} más',
              style: AppTextStyles.caption,
            ),
          ],

          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Ver lista completa →',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
