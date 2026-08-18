import 'dart:math';

import 'package:flutter/material.dart';
import 'package:palette_generator_plus/palette_generator_plus.dart';

import '../../main.dart' show routeObserver;
import '../../models/general_dashboard.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../common/club_book_cover.dart';

enum _YearShelfOrder { random, firstRead, latestFirst, rainbow }

class YearReadingShelf extends StatefulWidget {
  const YearReadingShelf({
    super.key,
    required this.year,
    required this.books,
    required this.onBookTap,
    this.onShare,
  });

  final int year;
  final List<YearShelfBook> books;
  final ValueChanged<YearShelfBook> onBookTap;
  final VoidCallback? onShare;

  @override
  State<YearReadingShelf> createState() => _YearReadingShelfState();
}

class _YearReadingShelfState extends State<YearReadingShelf>
    with SingleTickerProviderStateMixin
    implements RouteAware {
  bool _expanded = false;
  _YearShelfOrder _order = _YearShelfOrder.random;
  final _random = Random();
  final Map<String, double> _randomRanks = {};
  final Map<String, double> _colorHues = {}; // coverUrl → hue (0..360)
  bool _extractingColors = false;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      // Duración escalonada según número de libros visibles (máx 12)
      duration: Duration(
        milliseconds: 400 + widget.books.length.clamp(0, 12) * 85,
      ),
    );
    _seedRandomRanks(widget.books);
    _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant YearReadingShelf oldWidget) {
    super.didUpdateWidget(oldWidget);
    _seedRandomRanks(widget.books);
  }

  String _randomKey(YearShelfBook book, int index) =>
      '${book.id}|${book.bookId}|${book.finishedAt}|$index';

  void _seedRandomRanks(List<YearShelfBook> books) {
    for (final entry in books.indexed) {
      _randomRanks.putIfAbsent(
        _randomKey(entry.$2, entry.$1),
        _random.nextDouble,
      );
    }
  }

  void _reshuffle() {
    _randomRanks.clear();
    _seedRandomRanks(widget.books);
  }

  Future<void> _activateRainbow() async {
    setState(() {
      _order = _YearShelfOrder.rainbow;
      _extractingColors = true;
    });

    final booksWithCovers = widget.books
        .where((b) => b.coverUrl.trim().isNotEmpty)
        .toList();

    await Future.wait(booksWithCovers.map((book) async {
      final url = book.coverUrl;
      if (_colorHues.containsKey(url)) return;
      try {
        final provider = ResizeImage(NetworkImage(url), width: 80);
        final palette = await PaletteGenerator.fromImageProvider(
          provider,
          maximumColorCount: 24,
        );
        // Prefiere el color vibrante (más representativo visualmente)
        // sobre el dominante (que suele ser el color más frecuente, a menudo
        // blanco, negro o gris del fondo/texto).
        final color = palette.vibrantColor?.color ??
            palette.lightVibrantColor?.color ??
            palette.dominantColor?.color ??
            palette.lightMutedColor?.color ??
            palette.mutedColor?.color;
        if (color != null && mounted) {
          _colorHues[url] = HSLColor.fromColor(color).hue;
        }
      } catch (_) {
        if (mounted) _colorHues[url] = 360;
      }
    }));

    if (!mounted) return;
    setState(() => _extractingColors = false);
    _ctrl.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    _ctrl.forward(from: 0);
  }

  @override
  void didPush() {}
  @override
  void didPop() {}
  @override
  void didPushNext() {}

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indexed = widget.books.indexed.toList(growable: false)
      ..sort((left, right) {
        if (_order == _YearShelfOrder.random) {
          final leftRank = _randomRanks[_randomKey(left.$2, left.$1)] ?? 0;
          final rightRank = _randomRanks[_randomKey(right.$2, right.$1)] ?? 0;
          return leftRank.compareTo(rightRank);
        }
        if (_order == _YearShelfOrder.rainbow) {
          final leftHue = _colorHues[left.$2.coverUrl] ?? 360;
          final rightHue = _colorHues[right.$2.coverUrl] ?? 360;
          return leftHue.compareTo(rightHue);
        }
        final leftDate = DateTime.tryParse(left.$2.finishedAt);
        final rightDate = DateTime.tryParse(right.$2.finishedAt);
        if (leftDate == null && rightDate != null) return 1;
        if (leftDate != null && rightDate == null) return -1;
        final byDate = leftDate?.compareTo(rightDate!) ?? 0;
        if (byDate != 0) {
          return _order == _YearShelfOrder.latestFirst ? byDate : -byDate;
        }
        // When dates are equal, reverse index order for firstRead
        return _order == _YearShelfOrder.latestFirst
            ? left.$1.compareTo(right.$1)
            : right.$1.compareTo(left.$1);
      });
    final ordered = indexed.map((entry) => entry.$2).toList(growable: false);
    final visible = !_expanded && ordered.length > 12
        ? ordered.sublist(0, 12)
        : ordered;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4E7D3),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFFD3B58E)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF65452F).withValues(alpha: .10),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 11),
            child: Row(
              children: [
                const Icon(
                  Icons.local_library_outlined,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mi biblioteca ${widget.year}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ordered.length} '
                        '${ordered.length == 1 ? 'lectura' : 'lecturas'}',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_YearShelfOrder>(
                  tooltip: 'Ordenar biblioteca anual',
                  initialValue: _order,
                  onSelected: (value) {
                    if (value == _YearShelfOrder.rainbow) {
                      _activateRainbow();
                    } else {
                      setState(() {
                        if (value == _YearShelfOrder.random) _reshuffle();
                        _order = value;
                      });
                      _ctrl.forward(from: 0);
                    }
                  },
                  icon: const Icon(
                    Icons.swap_vert_rounded,
                    color: AppColors.primaryDark,
                    size: 21,
                  ),
                  itemBuilder: (context) => [
                    CheckedPopupMenuItem(
                      value: _YearShelfOrder.random,
                      checked: _order == _YearShelfOrder.random,
                      child: const Text('Orden aleatorio'),
                    ),
                    CheckedPopupMenuItem(
                      value: _YearShelfOrder.firstRead,
                      checked: _order == _YearShelfOrder.firstRead,
                      child: const Text('Primero del año'),
                    ),
                    CheckedPopupMenuItem(
                      value: _YearShelfOrder.latestFirst,
                      checked: _order == _YearShelfOrder.latestFirst,
                      child: const Text('Más recientes primero'),
                    ),
                    CheckedPopupMenuItem(
                      value: _YearShelfOrder.rainbow,
                      checked: _order == _YearShelfOrder.rainbow,
                      child: Row(
                        children: [
                          const Text('🌈  Arcoíris'),
                          if (_extractingColors) ...[
                            const Spacer(),
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.onShare != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Compartir mi año lector',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onShare,
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      color: AppColors.primaryDark,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (var start = 0; start < visible.length; start += 4)
            _YearShelfRow(
              shelfIndex: start ~/ 4,
              books: visible.sublist(
                start,
                start + 4 < visible.length ? start + 4 : visible.length,
              ),
              globalOffset: start,
              totalBooks: visible.length,
              controller: _ctrl,
              onBookTap: widget.onBookTap,
            ),
          if (ordered.length > 12)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                label: Text(
                  _expanded
                      ? 'Recoger estantería'
                      : 'Ver las ${ordered.length} lecturas',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _YearShelfRow extends StatelessWidget {
  const _YearShelfRow({
    required this.shelfIndex,
    required this.books,
    required this.globalOffset,
    required this.totalBooks,
    required this.controller,
    required this.onBookTap,
  });

  final int shelfIndex;
  final List<YearShelfBook> books;
  final int globalOffset;
  final int totalBooks;
  final AnimationController controller;
  final ValueChanged<YearShelfBook> onBookTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8D4B7), Color(0xFFF8EEDD)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: const _WoodGrain())),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Container(
              height: 17,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFB9834F),
                    Color(0xFF8A5937),
                    Color(0xFF68422E),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x55351F14),
                    blurRadius: 7,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            bottom: 28,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 8, 48, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < books.length; index++) ...[
                    if (index > 0)
                      SizedBox(
                        width:
                            5 +
                            ((books[index].id.hashCode.abs() + index) % 5)
                                .toDouble(),
                      ),
                    _CasualShelfBook(
                      book: books[index],
                      index: index,
                      globalIndex: globalOffset + index,
                      totalBooks: totalBooks,
                      controller: controller,
                      onTap: () => onBookTap(books[index]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            right: 9,
            bottom: 34,
            child: _ShelfDecoration(type: shelfIndex % 3),
          ),
        ],
      ),
    );
  }
}

class _CasualShelfBook extends StatefulWidget {
  const _CasualShelfBook({
    required this.book,
    required this.index,
    required this.globalIndex,
    required this.totalBooks,
    required this.controller,
    required this.onTap,
  });

  final YearShelfBook book;
  final int index;
  final int globalIndex;
  final int totalBooks;
  final AnimationController controller;
  final VoidCallback onTap;

  @override
  State<_CasualShelfBook> createState() => _CasualShelfBookState();
}

class _CasualShelfBookState extends State<_CasualShelfBook> {
  bool _lifted = false;

  @override
  Widget build(BuildContext context) {
    final seed = widget.book.id.hashCode.abs() + widget.index * 13;
    final height = 91.0 + (seed % 14);
    final angle = ((seed % 7) - 3) * .012;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // Animación de caída escalonada: cada libro cae en su momento
    final total = widget.totalBooks.clamp(1, 9999);
    final stagger = widget.globalIndex / total.toDouble();
    final start = (stagger * 0.55).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: widget.controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    return Transform.rotate(
      angle: angle,
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) {
          final t = anim.value;
          final dy = reduceMotion ? 0.0 : (1 - t) * -62.0;
          final opacity = reduceMotion ? 1.0 : t.clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Transform.translate(offset: Offset(0, dy), child: child),
          );
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            if (!reduceMotion) setState(() => _lifted = true);
          },
          onTapCancel: () {
            if (_lifted) setState(() => _lifted = false);
          },
          onTapUp: (_) {
            if (_lifted) setState(() => _lifted = false);
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _lifted ? -9 : 0, 0),
            child: ClubBookCover(
              title: widget.book.title,
              imageUrl: widget.book.coverUrl,
              width: 60,
              height: height,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShelfDecoration extends StatelessWidget {
  const _ShelfDecoration({required this.type});

  final int type;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      0 => const _ShelfPlant(),
      1 => const _ShelfCandle(),
      _ => const _ShelfVase(),
    };
  }
}

class _ShelfPlant extends StatelessWidget {
  const _ShelfPlant();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 67,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 20,
            left: 4,
            child: Transform.rotate(
              angle: -.35,
              child: const Icon(
                Icons.eco_rounded,
                color: Color(0xFF769066),
                size: 29,
              ),
            ),
          ),
          Positioned(
            bottom: 25,
            right: 1,
            child: Transform.rotate(
              angle: .42,
              child: const Icon(
                Icons.eco_rounded,
                color: Color(0xFF55764F),
                size: 26,
              ),
            ),
          ),
          Container(
            width: 29,
            height: 25,
            decoration: const BoxDecoration(
              color: Color(0xFFB66F58),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfCandle extends StatelessWidget {
  const _ShelfCandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 55,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFE7A43D),
            size: 19,
          ),
          Container(
            width: 30,
            height: 31,
            decoration: BoxDecoration(
              color: const Color(0xFFF3D7A5),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFD1A866)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfVase extends StatelessWidget {
  const _ShelfVase();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 69,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          const Positioned(
            top: 0,
            child: Icon(
              Icons.grass_rounded,
              color: Color(0xFF9B7B68),
              size: 34,
            ),
          ),
          Container(
            width: 29,
            height: 37,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9D7BC0), Color(0xFF684988)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
                bottomLeft: Radius.circular(13),
                bottomRight: Radius.circular(13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WoodGrain extends CustomPainter {
  const _WoodGrain();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7F5839).withValues(alpha: .075)
      ..strokeWidth = .8;
    for (double y = 9; y < size.height; y += 15) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 24) {
        path.quadraticBezierTo(x + 12, y + 3, x + 24, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
