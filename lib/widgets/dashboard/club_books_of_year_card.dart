import 'package:flutter/material.dart';

import '../../models/book_of_year.dart';
import '../../models/club_book_of_year.dart';
import '../../navigation/app_page_route.dart';
import '../../pages/book_of_year_page.dart';
import '../../pages/club_book_of_year_page.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../common/club_avatar.dart';
import '../common/club_card.dart';
import '../common/club_shimmer.dart';
import '../common/optimized_network_image.dart';

class ClubBooksOfYearCard extends StatefulWidget {
  const ClubBooksOfYearCard({
    super.key,
    this.currentUserName,
    this.currentUserId,
    this.loadMembers,
    this.pageBuilder,
    this.pageBuilderWithId,
    this.loadEdition,
    this.collectivePageBuilder,
  });
  final String? currentUserName;
  final String? currentUserId;
  final Future<List<ClubBookOfYearMember>> Function(int year)? loadMembers;
  final Widget Function(String? profile, int year)? pageBuilder;
  final Widget Function(String? profile, String? profileUserId, int year)?
  pageBuilderWithId;
  final Future<ClubBookOfYearEdition?> Function(int year)? loadEdition;
  final Widget Function(int year)? collectivePageBuilder;
  @override
  State<ClubBooksOfYearCard> createState() => _ClubBooksOfYearCardState();
}

class _ClubBooksOfYearCardState extends State<ClubBooksOfYearCard> {
  late final int year = DateTime.now().year;
  late Future<List<ClubBookOfYearMember>> _future = _load();

  Future<List<ClubBookOfYearMember>> _load() =>
      widget.loadMembers?.call(year) ?? ApiService().getClubBooksOfYear(year);

  List<ClubBookOfYearMember> _ordered(List<ClubBookOfYearMember> source) {
    final unique = <String, ClubBookOfYearMember>{};
    for (final member in source) {
      final key = member.userId.trim().isNotEmpty
          ? 'id:${member.userId.trim()}'
          : 'name:${member.userName.trim().toLowerCase()}';
      unique.putIfAbsent(key, () => member);
    }
    final result = unique.values.toList(growable: false);
    final current = widget.currentUserName?.trim().toLowerCase();
    if (current == null || current.isEmpty) return result;
    return [
      ...result.where(
        (member) => member.userName.trim().toLowerCase() == current,
      ),
      ...result.where(
        (member) => member.userName.trim().toLowerCase() != current,
      ),
    ];
  }

  bool _isCurrent(ClubBookOfYearMember member) =>
      widget.currentUserId?.trim().isNotEmpty == true &&
          member.userId.trim().isNotEmpty
      ? widget.currentUserId!.trim() == member.userId.trim()
      : widget.currentUserName?.trim().toLowerCase() ==
            member.userName.trim().toLowerCase();

  Future<void> _open(ClubBookOfYearMember member) async {
    final own = _isCurrent(member);
    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) =>
            widget.pageBuilderWithId?.call(
              own ? null : member.userName,
              own ? null : member.userId,
              year,
            ) ??
            widget.pageBuilder?.call(own ? null : member.userName, year) ??
            BookOfYearPage(
              profile: own ? null : member.userName,
              profileUserId: own || member.userId.isEmpty
                  ? null
                  : member.userId,
              initialYear: year,
            ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  void _showAll(List<ClubBookOfYearMember> members) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .65,
          maxChildSize: .9,
          builder: (_, controller) => Column(
            children: [
              Text(
                'Libros del año del club',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: members.length,
                  itemBuilder: (_, index) {
                    final member = members[index];
                    return ListTile(
                      leading: ClubAvatar(
                        nombre: member.userName,
                        imageUrl: member.avatarUrl,
                        size: 40,
                      ),
                      title: Text(_isCurrent(member) ? 'Tú' : member.userName),
                      subtitle: Text('${member.completedMonths}/12 meses'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _open(member);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<ClubBookOfYearMember>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const ClubCard(
          child: SizedBox(height: 218, child: CardListSkeleton(count: 2)),
        );
      }
      if (snapshot.hasError) {
        return ClubCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudieron cargar los libros del año.'),
              TextButton(
                onPressed: () => setState(() => _future = _load()),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      }
      final members = _ordered(snapshot.data ?? const []);
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final carouselHeight = 222.0 + ((textScale - 1) * 100).clamp(0, 90);
      final dark = Theme.of(context).brightness == Brightness.dark;
      return ClubCard(
        width: double.infinity,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF30283A), Color(0xFF352F2A)]
              : const [Color(0xFFF3EAF7), Color(0xFFFFF8E8)],
        ),
        borderColor: dark ? const Color(0xFF665875) : const Color(0xFFD9C8DF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado con trofeo grande y título prominente ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '🏆',
                  style: TextStyle(
                    fontSize: 32,
                    shadows: [
                      Shadow(
                        color: AppColors.gold.withValues(alpha: .3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'El año del club',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.3,
                        ),
                      ),
                      Text(
                        'Elección colectiva · cuadros personales',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: dark
                              ? const Color(0xFFAA9ABB)
                              : const Color(0xFF9A7EAB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // ── Libro colectivo en mini-card con fondo translúcido ──
            Container(
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: .06)
                    : Colors.white.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: .08)
                      : const Color(0xFFD9C8DF).withValues(alpha: .5),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: _CollectiveArea(
                year: year,
                loadEdition: widget.loadEdition,
                pageBuilder: widget.collectivePageBuilder,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // ── Sección de miembros ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Elecciones de los miembros',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _HeaderBadge(label: '$year'),
                if (members.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _HeaderBadge(
                    label:
                        '${members.length} ${members.length == 1 ? 'participante' : 'participantes'}',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Descubre sus cuadros personales',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: dark
                    ? const Color(0xFFAA9ABB)
                    : const Color(0xFF9A7EAB),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (members.isEmpty)
              const Text('Todavía no hay elecciones personales.')
            else
              SizedBox(
                height: carouselHeight,
                child: ListView.separated(
                  key: const ValueKey('club-books-of-year-carousel'),
                  scrollDirection: Axis.horizontal,
                  itemCount: members.length + (members.length > 4 ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (_, index) {
                    if (index == members.length) {
                      return _SeeAllCard(onTap: () => _showAll(members));
                    }
                    final member = members[index];
                    return _MemberCard(
                      member: member,
                      isCurrent: _isCurrent(member),
                      onTap: () => _open(member),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _CollectiveArea extends StatefulWidget {
  const _CollectiveArea({
    required this.year,
    this.loadEdition,
    this.pageBuilder,
  });
  final int year;
  final Future<ClubBookOfYearEdition?> Function(int year)? loadEdition;
  final Widget Function(int year)? pageBuilder;
  @override
  State<_CollectiveArea> createState() => _CollectiveAreaState();
}

class _CollectiveAreaState extends State<_CollectiveArea> {
  Future<ClubBookOfYearEdition?> _load() =>
      widget.loadEdition?.call(widget.year) ??
      ApiService().getClubBookOfYearEdition(widget.year);
  late Future<ClubBookOfYearEdition?> _future = _load();

  Future<void> _open() async {
    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) =>
            widget.pageBuilder?.call(widget.year) ??
            ClubBookOfYearPage(initialYear: widget.year),
      ),
    );
    if (mounted) {
      setState(() {
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ClubBookOfYearEdition?>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(height: 92, child: CardListSkeleton(count: 1));
      }
      if (snapshot.hasError) {
        return Row(
          children: [
            const Expanded(
              child: Text('No se pudo cargar la elección colectiva.'),
            ),
            TextButton(
              onPressed: () => setState(() => _future = _load()),
              child: const Text('Reintentar'),
            ),
          ],
        );
      }
      final edition = snapshot.data;
      final winner = edition?.winner;
      final status = edition == null ? 'No iniciado' : _status(edition.status);
      return InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (winner != null) ...[
                _CollectiveCover(winner),
                const SizedBox(width: AppSpacing.md),
              ] else if (edition?.status == 'PREPARING' &&
                  edition!.candidates.isNotEmpty) ...[
                SizedBox(
                  width: 62,
                  height: 62,
                  child: Stack(
                    children: [
                      for (
                        var index = 0;
                        index < edition.candidates.take(3).length;
                        index++
                      )
                        Positioned(
                          left: index * 10,
                          child: _CollectiveCover(
                            edition.candidates[index],
                            crown: false,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ] else
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.md),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 40,
                    color: AppColors.gold,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Libro del año del club',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    // Badge de estado en su propia línea — sin riesgo de overflow
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: AppColors.gold.withValues(alpha: .9),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (winner != null)
                      Text(
                        winner.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )
                    else
                      Text(
                        edition == null
                            ? 'La votación no ha comenzado'
                            : '${edition.candidates.length} lecturas candidatas',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (edition?.status == 'PREPARING') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (edition?.candidatesSyncedAt != null)
                            Text(
                              'Act. ${edition!.candidatesSyncedAt!.toLocal().day}/${edition.candidatesSyncedAt!.toLocal().month}  ·  ',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          Text(
                            'Revisar →',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      );
    },
  );

  String _status(String value) =>
      const {
        'NOT_STARTED': 'No iniciado',
        'PREPARING': 'Edición en preparación',
        'QUALIFYING': 'Votación inicial',
        'ROUND_PENDING': 'Ronda preparada',
        'ROUND_OPEN': 'Vota ahora',
        'TIEBREAK': 'Desempate',
        'FINISHED': 'Finalizado',
      }[value] ??
      value;
}

class _CollectiveCover extends StatelessWidget {
  const _CollectiveCover(this.book, {this.crown = true});
  final ClubBookOfYearCandidate book;
  final bool crown;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: book.coverUrl.isEmpty
            ? Container(
                width: 42,
                height: 62,
                color: Theme.of(context).colorScheme.surface,
                child: const Icon(Icons.menu_book),
              )
            : OptimizedNetworkImage(
                url: book.coverUrl,
                width: 42,
                height: 62,
                fit: BoxFit.cover,
              ),
      ),
      if (crown)
        const Positioned(
          right: -8,
          top: -9,
          child: Icon(
            Icons.workspace_premium_rounded,
            size: 20,
            color: AppColors.gold,
          ),
        ),
    ],
  );
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .62),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isCurrent,
    required this.onTap,
  });
  final ClubBookOfYearMember member;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final winner = member.winner;
    final preview = member.previewSlots;
    final started = member.completedMonths > 0 || member.selections.isNotEmpty;
    final semantics = [
      'Abrir Libro del año de ${member.userName}',
      '${member.completedMonths} de 12 meses elegidos',
      if (winner != null) 'Libro del año elegido: ${winner.title}',
    ].join('. ');
    final tones = Theme.of(context).brightness == Brightness.dark
        ? [
            const Color(0xFF342C38),
            const Color(0xFF293632),
            const Color(0xFF3A302C),
          ]
        : [
            const Color(0xFFF5ECF7),
            const Color(0xFFEDF5F0),
            const Color(0xFFF8EFE8),
          ];
    final tone = tones[member.userName.hashCode.abs() % tones.length];
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: SizedBox(
        width: 158,
        child: Material(
          color: tone,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClubAvatar(
                        nombre: member.userName,
                        imageUrl: member.avatarUrl,
                        size: 34,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          isCurrent ? 'Tú' : member.userName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${member.completedMonths}/12 meses',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: (member.completedMonths / 12).clamp(0, 1),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: .7),
                  ),
                  const Spacer(),
                  if (winner != null)
                    Center(child: _WinnerCover(book: winner))
                  else if (preview.isNotEmpty)
                    _AdvancedCovers(items: preview)
                  else if (!started)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Todavía no ha empezado',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    )
                  else
                    const _EmptyCovers(),
                  if (member.pendingDuels > 0)
                    Text(
                      '${member.pendingDuels} ${member.pendingDuels == 1 ? 'duelo pendiente' : 'duelos pendientes'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    'Ver cuadro',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdvancedCovers extends StatelessWidget {
  const _AdvancedCovers({required this.items});
  final List<ClubBookOfYearPreviewBook> items;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 61,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final item in items.take(2))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: item.book == null
                ? const _PendingCover()
                : _Cover(item.book!, width: 38, height: 56),
          ),
      ],
    ),
  );
}

class _PendingCover extends StatelessWidget {
  const _PendingCover();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('book-of-year-preview-pending'),
    width: 38,
    height: 56,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .62),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.border),
    ),
    child: const RotatedBox(
      quarterTurns: 3,
      child: Text(
        'Pendiente',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _WinnerCover extends StatelessWidget {
  const _WinnerCover({required this.book});
  final BookOfYearBook book;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      _Cover(book, width: 42, height: 62),
      const Positioned(
        right: -9,
        top: -10,
        child: Icon(
          Icons.workspace_premium_rounded,
          color: AppColors.gold,
          size: 22,
        ),
      ),
    ],
  );
}

class _EmptyCovers extends StatelessWidget {
  const _EmptyCovers();
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [_CoverPlaceholder(), SizedBox(width: 6), _CoverPlaceholder()],
  );
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    width: 35,
    height: 52,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: const Icon(
      Icons.menu_book_outlined,
      size: 16,
      color: AppColors.textMuted,
    ),
  );
}

class _SeeAllCard extends StatelessWidget {
  const _SeeAllCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_rounded),
            SizedBox(height: AppSpacing.sm),
            Text('Ver todos', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    ),
  );
}

class _Cover extends StatelessWidget {
  const _Cover(this.book, {required this.width, required this.height});
  final BookOfYearBook book;
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: book.coverUrl.isEmpty
        ? Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surface,
            child: const Icon(Icons.menu_book, size: 16),
          )
        : OptimizedNetworkImage(
            url: book.coverUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
          ),
  );
}
