import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../models/general_dashboard.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../common/club_book_cover.dart';

// ─────────────────────────────────────────────
// Nombres de meses en español
// ─────────────────────────────────────────────
const _months = [
  'Enero', 'Febrero', 'Marzo', 'Abril',
  'Mayo', 'Junio', 'Julio', 'Agosto',
  'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

// ─────────────────────────────────────────────
// Widget principal
// ─────────────────────────────────────────────

class MonthlyReadingShelf extends StatefulWidget {
  const MonthlyReadingShelf({
    super.key,
    required this.year,
    required this.month,
    required this.books,
    required this.onBookTap,
  });

  final int year;
  final int month;
  final List<MonthlyFinishedBook> books;
  final ValueChanged<MonthlyFinishedBook> onBookTap;

  @override
  State<MonthlyReadingShelf> createState() => _MonthlyReadingShelfState();
}

class _MonthlyReadingShelfState extends State<MonthlyReadingShelf>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 380 + widget.books.length * 95),
    );
    // initState se llama cada vez que Flutter crea un nuevo State,
    // lo que ocurre cuando el widget recibe una key diferente.
    // El GeneralDashboardPage renueva _shelfKey en cada load/reload,
    // garantizando que la animación arranca de cero al entrar a la pantalla.
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = _months[(widget.month - 1).clamp(0, 11)];

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
          // ── Cabecera ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 11),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estantería de $monthLabel',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.books.length} '
                        '${widget.books.length == 1 ? 'lectura este mes' : 'lecturas este mes'}',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Filas de estantería ──
          for (var start = 0; start < widget.books.length; start += 4)
            _MonthlyShelfRow(
              shelfIndex: start ~/ 4,
              books: widget.books.sublist(
                start,
                (start + 4).clamp(0, widget.books.length),
              ),
              globalOffset: start,
              totalBooks: widget.books.length,
              controller: _ctrl,
              onBookTap: widget.onBookTap,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Fila de estantería
// ─────────────────────────────────────────────

class _MonthlyShelfRow extends StatelessWidget {
  const _MonthlyShelfRow({
    required this.shelfIndex,
    required this.books,
    required this.globalOffset,
    required this.totalBooks,
    required this.controller,
    required this.onBookTap,
  });

  final int shelfIndex;
  final List<MonthlyFinishedBook> books;
  final int globalOffset;
  final int totalBooks;
  final AnimationController controller;
  final ValueChanged<MonthlyFinishedBook> onBookTap;

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
          // Tablón
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
          // Libros con animación
          Positioned.fill(
            bottom: 28,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 8, 48, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < books.length; i++) ...[
                    if (i > 0)
                      SizedBox(
                        width: 5 +
                            ((books[i].id.hashCode.abs() + i) % 5).toDouble(),
                      ),
                    _AnimatedMonthlyBook(
                      book: books[i],
                      index: i,
                      globalIndex: globalOffset + i,
                      totalBooks: totalBooks,
                      controller: controller,
                      onTap: () => onBookTap(books[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Decoración
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

// ─────────────────────────────────────────────
// Libro animado: cae desde arriba y se coloca
// ─────────────────────────────────────────────

class _AnimatedMonthlyBook extends StatefulWidget {
  const _AnimatedMonthlyBook({
    required this.book,
    required this.index,
    required this.globalIndex,
    required this.totalBooks,
    required this.controller,
    required this.onTap,
  });

  final MonthlyFinishedBook book;
  final int index;
  final int globalIndex;
  final int totalBooks;
  final AnimationController controller;
  final VoidCallback onTap;

  @override
  State<_AnimatedMonthlyBook> createState() => _AnimatedMonthlyBookState();
}

class _AnimatedMonthlyBookState extends State<_AnimatedMonthlyBook> {
  bool _lifted = false;

  @override
  Widget build(BuildContext context) {
    final seed = widget.book.id.hashCode.abs() + widget.index * 13;
    final height = 91.0 + (seed % 14);
    final angle = ((seed % 7) - 3) * .012;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // Cada libro se coloca escalonado en el tiempo
    final stagger = widget.totalBooks <= 1
        ? 0.0
        : widget.globalIndex / (widget.totalBooks - 1).toDouble();
    // La ventana de animación de este libro va de stagger*0.6 a stagger*0.6+0.4
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
          // Empieza 60px arriba, cae a su posición
          final dy = reduceMotion ? 0.0 : (1 - t) * -60.0;
          final opacity = reduceMotion ? 1.0 : t.clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: child,
            ),
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
            duration:
                reduceMotion ? Duration.zero : const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _lifted ? -9 : 0, 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClubBookCover(
                  title: widget.book.title,
                  imageUrl: widget.book.coverUrl,
                  width: 60,
                  height: height,
                  borderRadius: BorderRadius.circular(4),
                ),
                // Estrellitas en el lomo superior
                if (widget.book.rating != null && widget.book.rating! > 0)
                  Positioned(
                    top: 4,
                    left: 0,
                    right: 0,
                    child: _RatingBadge(rating: widget.book.rating!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Badge de valoración (estrellas compactas)
// ─────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    // Máx 5 estrellas. Mostramos el número compacto con ⭐
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .62),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 9),
            const SizedBox(width: 2),
            Text(
              rating == rating.roundToDouble()
                  ? rating.toInt().toString()
                  : rating.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Decoraciones de estantería (planta, vela, jarrón)
// ─────────────────────────────────────────────

class _ShelfDecoration extends StatelessWidget {
  const _ShelfDecoration({required this.type});
  final int type;

  @override
  Widget build(BuildContext context) => switch (type) {
        0 => const _ShelfPlant(),
        1 => const _ShelfCandle(),
        _ => const _ShelfVase(),
      };
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
              child: const Icon(Icons.eco_rounded,
                  color: Color(0xFF769066), size: 29),
            ),
          ),
          Positioned(
            bottom: 25,
            right: 1,
            child: Transform.rotate(
              angle: .42,
              child: const Icon(Icons.eco_rounded,
                  color: Color(0xFF55764F), size: 26),
            ),
          ),
          Container(
            width: 29,
            height: 25,
            decoration: const BoxDecoration(
              color: Color(0xFFB66F58),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(9)),
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
          const Icon(Icons.local_fire_department_rounded,
              color: Color(0xFFE7A43D), size: 19),
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
            child: Icon(Icons.grass_rounded,
                color: Color(0xFF9B7B68), size: 34),
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
  bool shouldRepaint(covariant CustomPainter old) => false;
}
