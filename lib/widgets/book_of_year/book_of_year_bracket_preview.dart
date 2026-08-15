import 'package:flutter/material.dart';

import '../../models/book_of_year.dart';
import '../../theme/app_colors.dart';
import '../common/optimized_network_image.dart';

class BookOfYearBracketPreview extends StatelessWidget {
  const BookOfYearBracketPreview({
    super.key,
    required this.board,
    required this.onTap,
  });

  final BookOfYearBoard board;
  final VoidCallback onTap;

  static const size = Size(640, 250);

  @override
  Widget build(BuildContext context) {
    final firstRound = _duels('MONTH_PAIR', 6);
    final finalistRound = _duels('SEMIFINAL', 3);

    return Semantics(
      button: true,
      label: 'Abrir cuadro completo de Libro del año',
      child: InkWell(
        key: const ValueKey('book-of-year-bracket-preview'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: size.height,
          child: SingleChildScrollView(
            key: const ValueKey('book-of-year-preview-scroll'),
            scrollDirection: Axis.horizontal,
            child: SizedBox.fromSize(
              size: size,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      key: const ValueKey('book-of-year-preview-connections'),
                      painter: _PreviewConnectionsPainter(
                        color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? .62
                              : .52,
                        ),
                      ),
                    ),
                  ),
                  const _PreviewLabels(),
                  for (var pair = 0; pair < 6; pair++)
                    Positioned(
                      left: 8,
                      top: _PreviewLayout.pairTop(pair),
                      child: _MonthPair(
                        first: board.months[pair * 2],
                        second: board.months[pair * 2 + 1],
                      ),
                    ),
                  for (var index = 0; index < 6; index++)
                    Positioned(
                      left: _PreviewLayout.firstX,
                      top: _PreviewLayout.firstTop(index),
                      child: _RoundSlot(
                        key: ValueKey('preview-first-${index + 1}'),
                        book: firstRound[index]?.winner,
                        locked: firstRound[index]?.unlocked != true,
                      ),
                    ),
                  for (var index = 0; index < 3; index++)
                    Positioned(
                      left: _PreviewLayout.finalistX,
                      top: _PreviewLayout.finalistTop(index),
                      child: _RoundSlot(
                        key: ValueKey('preview-finalist-${index + 1}'),
                        book:
                            finalistRound[index]?.winner ?? _finalistAt(index),
                        locked: finalistRound[index]?.unlocked != true,
                      ),
                    ),
                  Positioned(
                    left: _PreviewLayout.winnerX,
                    top: _PreviewLayout.winnerTop,
                    child: _WinnerSlot(book: board.winner),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<BookOfYearDuel?> _duels(String phase, int count) =>
      List.generate(count, (index) {
        for (final duel in board.duels) {
          if (duel.phase == phase && duel.position == index + 1) return duel;
        }
        return null;
      });

  BookOfYearBook? _finalistAt(int index) =>
      index < board.finalists.length ? board.finalists[index] : null;
}

class _PreviewLayout {
  static const firstX = 224.0;
  static const finalistX = 390.0;
  static const winnerX = 554.0;
  static const slotSize = Size(42, 49);
  static const pairHeight = 32.0;
  static const startY = 31.0;
  static const stepY = 35.0;

  static double pairTop(int index) => startY + index * stepY;
  static double pairCenter(int index) => pairTop(index) + pairHeight / 2;
  static double firstTop(int index) => pairCenter(index) - slotSize.height / 2;
  static double firstCenter(int index) => firstTop(index) + slotSize.height / 2;
  static double finalistTop(int index) =>
      (firstCenter(index * 2) + firstCenter(index * 2 + 1)) / 2 -
      slotSize.height / 2;
  static double finalistCenter(int index) =>
      finalistTop(index) + slotSize.height / 2;
  static double get winnerTop => finalistCenter(1) - slotSize.height / 2;
}

class _PreviewLabels extends StatelessWidget {
  const _PreviewLabels();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 10, fontWeight: FontWeight.w800);
    return const Stack(
      children: [
        Positioned(left: 8, top: 5, child: Text('Meses', style: style)),
        Positioned(
          left: _PreviewLayout.firstX - 8,
          top: 5,
          child: Text('Primera ronda', style: style),
        ),
        Positioned(
          left: _PreviewLayout.finalistX - 4,
          top: 5,
          child: Text('Finalistas', style: style),
        ),
        Positioned(
          left: _PreviewLayout.winnerX - 8,
          top: 5,
          child: Text('Libro del año', style: style),
        ),
      ],
    );
  }
}

class _MonthPair extends StatelessWidget {
  const _MonthPair({required this.first, required this.second});

  final BookOfYearMonth first;
  final BookOfYearMonth second;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('preview-pair-${first.month}-${second.month}'),
    width: 156,
    height: _PreviewLayout.pairHeight,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Expanded(child: _MonthCandidate(month: first)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Text('vs', style: TextStyle(fontSize: 8)),
        ),
        Expanded(child: _MonthCandidate(month: second)),
      ],
    ),
  );
}

class _MonthCandidate extends StatelessWidget {
  const _MonthCandidate({required this.month});

  final BookOfYearMonth month;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _TinyCover(book: month.selection, locked: month.locked, width: 16),
      const SizedBox(width: 3),
      Expanded(
        child: Text(
          _monthShort(month.month),
          maxLines: 1,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _RoundSlot extends StatelessWidget {
  const _RoundSlot({super.key, required this.book, required this.locked});

  final BookOfYearBook? book;
  final bool locked;

  @override
  Widget build(BuildContext context) => Container(
    width: _PreviewLayout.slotSize.width,
    height: _PreviewLayout.slotSize.height,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: AppColors.border),
    ),
    child: _TinyCover(book: book, locked: locked, width: 34),
  );
}

class _WinnerSlot extends StatelessWidget {
  const _WinnerSlot({required this.book});

  final BookOfYearBook? book;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('preview-annual-winner'),
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('👑', style: TextStyle(fontSize: 16)),
      Container(
        width: 48,
        height: 58,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.primary),
        ),
        child: _TinyCover(book: book, locked: book == null, width: 40),
      ),
    ],
  );
}

class _TinyCover extends StatelessWidget {
  const _TinyCover({
    required this.book,
    required this.locked,
    required this.width,
  });

  final BookOfYearBook? book;
  final bool locked;
  final double width;

  @override
  Widget build(BuildContext context) {
    final item = book;
    if (item == null) {
      return Container(
        key: ValueKey(locked ? 'preview-locked-slot' : 'preview-pending-slot'),
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          locked ? Icons.lock_outline_rounded : Icons.more_horiz_rounded,
          size: width.clamp(12, 18),
          color: AppColors.textMuted,
        ),
      );
    }
    return ClipRRect(
      key: ValueKey('preview-book-${item.id}'),
      borderRadius: BorderRadius.circular(4),
      child: item.coverUrl.isEmpty
          ? ColoredBox(
              color: AppColors.primaryLight,
              child: Icon(Icons.menu_book_rounded, size: width.clamp(12, 18)),
            )
          : OptimizedNetworkImage(
              url: item.coverUrl,
              width: width,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
    );
  }
}

class _PreviewConnectionsPainter extends CustomPainter {
  const _PreviewConnectionsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    void connect(Offset from, Offset to) {
      final middle = (from.dx + to.dx) / 2;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(middle, from.dy)
        ..lineTo(middle, to.dy)
        ..lineTo(to.dx, to.dy);
      canvas.drawPath(path, paint);
    }

    for (var index = 0; index < 6; index++) {
      connect(
        Offset(164, _PreviewLayout.pairCenter(index)),
        Offset(_PreviewLayout.firstX, _PreviewLayout.firstCenter(index)),
      );
    }
    for (var index = 0; index < 3; index++) {
      for (final first in [index * 2, index * 2 + 1]) {
        connect(
          Offset(
            _PreviewLayout.firstX + _PreviewLayout.slotSize.width,
            _PreviewLayout.firstCenter(first),
          ),
          Offset(
            _PreviewLayout.finalistX,
            _PreviewLayout.finalistCenter(index),
          ),
        );
      }
    }
    for (var index = 0; index < 3; index++) {
      connect(
        Offset(
          _PreviewLayout.finalistX + _PreviewLayout.slotSize.width,
          _PreviewLayout.finalistCenter(index),
        ),
        Offset(_PreviewLayout.winnerX, _PreviewLayout.finalistCenter(1)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewConnectionsPainter oldDelegate) =>
      oldDelegate.color != color;
}

String _monthShort(int month) => const [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
][month - 1];
